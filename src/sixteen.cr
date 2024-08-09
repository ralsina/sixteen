require "./color"
require "baked_file_system"
require "colorize"
require "file_utils"
require "yaml"

module Sixteen
  extend self
  VERSION = "0.2.0"

  class DataFiles
    extend BakedFileSystem

    bake_folder "../base16", __DIR__
  end

  struct Theme
    include YAML::Serializable

    property system : String
    property name : String
    property author : String
    property variant : String
    property slug : String?
    property palette : Hash(String, Color)
    property description : String = ""

    def slug : String
      return slug unless @slug.nil?

      slug = name.unicode_normalize(:nfkd)
        .chars.reject! { |character|
        !character.ascii_letter? && (character != ' ') && (character != '-')
      }.join("").downcase.gsub(" ", "-")
      slug
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
      key = "base#{key.to_s(16)}"
      palette[key]
    end
  end

  def self.theme(name : String) : Theme
    tfile = DataFiles.get("/#{name}.yaml")
    Theme.from_yaml(tfile.gets_to_end)
  rescue BakedFileSystem::NoSuchFileError
    raise Exception.new("Theme not found: #{name}")
  end
end
