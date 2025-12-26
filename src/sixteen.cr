require "./color"
require "baked_file_system"
require "colorize"
require "file_utils"
require "yaml"

module Sixteen
  extend self
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  class DataFiles
    extend BakedFileSystem

    macro bake_selected_themes
      {% if env("SIXTEEN_THEMES") %}
        {% for theme in env("SIXTEEN_THEMES").split "," %}
          bake_file {{ theme }}+".yaml", {{ read_file "#{__DIR__}/../base16/" + theme + ".yaml" }}
        {% end %}
      {% end %}
    end

    {% if flag?(:nothemes) %}
      bake_selected_themes
    {% else %}
      bake_folder "../base16", __DIR__
    {% end %}
  end

  struct ThemeFamily
    property base_name : String
    property dark_themes : Array(String)
    property light_themes : Array(String)
    property other_variants : Array(String)

    def initialize(@base_name : String)
      @dark_themes = [] of String
      @light_themes = [] of String
      @other_variants = [] of String
    end
  end

  struct Theme
    include YAML::Serializable

    property system : String
    property name : String
    property author : String
    property variant : String
    property slug : String = ""
    property palette : Hash(String, Color)
    property description : String = ""

    def initialize
      @system = "base16"
      @name = ""
      @author = ""
      @variant = ""
      @slug = ""
      @palette = Hash(String, Color).new
      @description = ""
    end

    def slug : String
      return @slug unless @slug.empty?

      @slug = name.unicode_normalize(:nfkd)
        .chars.reject! { |character|
        !character.ascii_letter? && (character != ' ') && (character != '-')
      }.join("").downcase.gsub(" ", "-")
      @slug
    end

    # The separator is configurable because the base16 spec
    # requires names like `foo-bar` but some template systems
    # don't like those
    def context(separator : String = "-")
      data = Hash(String, Bool | String | Int32 | Float64).new

      data["scheme-name".gsub("-", separator)] = name
      data["scheme-author".gsub("-", separator)] = author
      data["scheme-description".gsub("-", separator)] = description
      data["scheme-slug".gsub("-", separator)] = slug
      data["scheme-slug-underscored".gsub("-", separator)] = slug.gsub("-", "_")
      data["scheme-system".gsub("-", separator)] = system
      data["scheme-variant".gsub("-", separator)] = variant
      data["scheme-is-#{variant}-variant".gsub("-", separator)] = true
      palette.each do |k, v|
        data["#{k}-hex".gsub("-", separator)] = v.hex
        data["#{k}-hex-bgr".gsub("-", separator)] = v.hex_bgr
        data["#{k}-hex-r".gsub("-", separator)] = v.r.to_s(16)
        data["#{k}-hex-g".gsub("-", separator)] = v.g.to_s(16)
        data["#{k}-hex-b".gsub("-", separator)] = v.b.to_s(16)
        data["#{k}-rgb-r".gsub("-", separator)] = v.r.to_s
        data["#{k}-rgb-g".gsub("-", separator)] = v.g.to_s
        data["#{k}-rgb-b".gsub("-", separator)] = v.b.to_s
        data["#{k}-dec-r".gsub("-", separator)] = v.r/255
        data["#{k}-dec-g".gsub("-", separator)] = v.g/255
        data["#{k}-dec-b".gsub("-", separator)] = v.b/255
      end
      data
    end

    def term_palette
      pal = ""
      palette.each do |_, v|
        pal += "  ".colorize.back(v.colorize).to_s
      end
      pal
    end

    def to_s
      doc = "Scheme:      #{name}\nAuthor:      #{author}\n"
      doc += "Description: #{description}\n" unless description.empty?
      doc += "Variant:     #{variant}\n" unless variant.empty?
      doc += "Palette:     #{term_palette}\n"
      doc
    end

    def [](key : String) : Color
      key = "base#{key}" unless key.starts_with?("base")
      palette[key]
    end

    def [](key : Int) : Color
      palette["base#{key.to_s(16).rjust(2, '0').upcase}"]
    end

    # Returns the color in the palette that contrasts better
    # with the given color
    def contrasting(key : Int) : Color
      color = self[key]
      contrast = 0.0
      contrast_key = 0
      (0..15).each do |k|
        next if k == key
        c = self[k].contrast(color)
        if c > contrast
          contrast = c
          contrast_key = k
        end
      end
      self[contrast_key]
    end

    # Create a new theme with inverted colors
    def invert_for_theme(target : Symbol) : Theme
      target_variant = target == :light ? "light" : "dark"

      new_palette = palette.transform_values do |color|
        color.invert_for_theme(target)
      end

      # Create a new theme by copying and modifying properties
      new_theme = Theme.new
      new_theme.system = system
      new_theme.name = "#{name} (Auto-generated #{target_variant.capitalize})"
      new_theme.author = "#{author} + auto-generated"
      new_theme.variant = target_variant
      new_theme.slug = slug + "-auto-#{target_variant}"
      new_theme.palette = new_palette
      new_theme.description = description.empty? ? "Auto-generated #{target_variant} variant" : description
      new_theme
    end
  end

  # Get available theme names
  def self.available_themes : Array(String)
    DataFiles.files.select { |fname|
      fname.path.ends_with?(".yaml")
    }.map { |fname|
      File.basename(fname.path, ".yaml")
    }.sort!
  end

  # Find theme families (groups of related dark/light themes)
  def self.theme_families : Array(ThemeFamily)
    families = Hash(String, ThemeFamily).new
    themes = available_themes

    themes.each do |theme_name|
      begin
        theme = theme(theme_name)
        base_name = extract_base_name(theme_name)

        families[base_name] ||= ThemeFamily.new(base_name)
        family = families[base_name]

        case theme.variant
        when "dark"
          family.dark_themes << theme_name
        when "light"
          family.light_themes << theme_name
        else
          family.other_variants << theme_name
        end
      rescue
        # Skip themes that can't be loaded
      end
    end

    families.values.to_a
  end

  # Get light variant of a theme (existing or generated)
  def self.light_variant(theme_name : String) : Theme
    theme = theme_with_fallback(theme_name, "light")
    return theme if theme.variant == "light"

    # Try to find existing light variant
    existing_name = find_variant(theme_name, "light")
    return theme(existing_name) if existing_name

    # Generate by inverting colors
    theme.invert_for_theme(:light)
  rescue
    raise Exception.new("Theme not found: #{theme_name}")
  end

  # Get dark variant of a theme (existing or generated)
  def self.dark_variant(theme_name : String) : Theme
    theme = theme_with_fallback(theme_name, "dark")
    return theme if theme.variant == "dark"

    # Try to find existing dark variant
    existing_name = find_variant(theme_name, "dark")
    return theme(existing_name) if existing_name

    # Generate by inverting colors
    theme.invert_for_theme(:dark)
  rescue
    raise Exception.new("Theme not found: #{theme_name}")
  end

  # Extract base name from theme name (remove -light, -dark, etc.)
  private def self.extract_base_name(name : String) : String
    # Handle special cases first
    special_cases = {
      "catppuccin-latte"     => "catppuccin",
      "catppuccin-frappe"    => "catppuccin",
      "catppuccin-macchiato" => "catppuccin",
      "catppuccin-mocha"     => "catppuccin",
      "rose-pine-dawn"       => "rose-pine",
      "rose-pine-moon"       => "rose-pine",
    }

    return special_cases[name] if special_cases[name]?

    # Standard patterns
    name = name.sub(/-light$/, "")
    name = name.sub(/-dark$/, "")
    name = name.sub(/-terminal$/, "")
    name = name.sub(/-hard$/, "")
    name = name.sub(/-medium$/, "")
    name = name.sub(/-soft$/, "")
    name = name.sub(/-pale$/, "")
    name = name.sub(/-contrast-plus-plus$/, "")
    name = name.sub(/-contrast-plus$/, "")
    name = name.sub(/-warm$/, "")
    name = name.sub(/-white$/, "")
    name = name.sub(/-eleven$/, "")
    name = name.sub(/-fifteen$/, "")

    name
  end

  # Find variant of a theme by checking naming patterns
  private def self.find_variant(theme_name : String, target_variant : String) : String?
    base_name = extract_base_name(theme_name)

    # Special case mappings
    special_mappings = {
      {"catppuccin", "light"} => "catppuccin-latte",
      {"catppuccin", "dark"}  => "catppuccin-mocha",
      {"rose-pine", "light"}  => "rose-pine-dawn",
    }

    key = {base_name, target_variant}
    return special_mappings[key] if special_mappings[key]?

    # Standard patterns
    candidates = ["#{base_name}-#{target_variant}"]

    # For themes that have explicit suffixes, try removing suffix
    if theme_name.includes?("-dark") || theme_name.includes?("-light")
      candidates << base_name
    end

    available = available_themes
    candidates.find { |candidate| available.includes?(candidate) && candidate != theme_name }
  end

  # Find theme by name or base name with variant preference
  def self.theme_with_fallback(name : String, preferred_variant : String? = nil) : Theme
    # First try exact match
    theme(name)
  rescue
    # Try to find theme by base name with preferred variant
    available = available_themes
    base_name = extract_base_name(name)

    candidates = [] of String

    case preferred_variant
    when "light"
      candidates << "#{base_name}-light"
      candidates << "#{base_name}"
    when "dark"
      candidates << "#{base_name}-dark"
      candidates << "#{base_name}"
    else
      # No preference, try dark first (most common)
      candidates << "#{base_name}-dark"
      candidates << "#{base_name}-light"
      candidates << base_name
    end

    candidates.each do |candidate|
      if available.includes?(candidate)
        return theme(candidate)
      end
    end

    raise Exception.new("Theme not found: #{name}")
  end

  def self.theme(name : String) : Theme
    tfile = DataFiles.get("/#{name}.yaml")
    Theme.from_yaml(tfile.gets_to_end)
  rescue BakedFileSystem::NoSuchFileError
    raise Exception.new("Theme not found: #{name}")
  end
end
