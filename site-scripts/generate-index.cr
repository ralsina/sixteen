#!/usr/bin/env crystal
require "yaml"
require "json"
require "../src/sixteen"

struct ThemeInfo
  include YAML::Serializable

  property name : String
  property author : String
  property variant : String
  property palette : Hash(String, String)
end

record ThemeData, name : String, author : String, slug : String, variant : String, palette : Array(String)

# Helper function to extract base name from theme name
def extract_base_name(name : String) : String
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

# Group themes by family
families = Hash(String, Array(ThemeData)).new

# Read all YAML files from base16 directory
base16_dir = File.join(File.dirname(__FILE__), "..", "base16")
Dir.glob(File.join(base16_dir, "*.yaml")).sort.each do |file|
  begin
    # Get theme name from filename
    theme_slug = File.basename(file, ".yaml")

    # Parse YAML
    theme = ThemeInfo.from_yaml(File.read(file))

    # Get palette colors (base00-base0F)
    palette = (0..15).map do |i|
      key = sprintf("base%02X", i)
      theme.palette[key]? || "#000000"
    end

    # Get base name (family name) using the library's extract_base_name logic
    base_name = extract_base_name(theme_slug)

    theme_data = ThemeData.new(
      theme.name,
      theme.author,
      theme_slug,
      theme.variant.empty? ? "unknown" : theme.variant,
      palette
    )

    families[base_name] ||= [] of ThemeData
    families[base_name] << theme_data
  rescue ex
    puts "Error loading #{file}: #{ex.message}"
  end
end

# Convert to array and sort
output = families.map do |base_name, themes|
  # Sort themes: dark first, then light, then others
  sorted_themes = themes.sort_by do |t|
    case t.variant
    when "dark"  then 0
    when "light" then 1
    else              2
    end
  end

  {
    "base_name" => base_name,
    "themes"    => sorted_themes.map { |t|
      {
        "name"    => t.name,
        "author"  => t.author,
        "slug"    => t.slug,
        "variant" => t.variant,
        "palette" => t.palette,
      }
    },
  }
end.sort_by!(&.["base_name"].to_s)

puts output.to_json
