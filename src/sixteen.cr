require "baked_file_system"
require "colorize"
require "file_utils"
require "yaml"

module Sixteen
  extend self
  VERSION = "0.1.0"

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
    property palette : Hash(String, String)
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
        data["#{k}-hex".gsub("-", separator)] = v
        data["#{k}-hex-bgr".gsub("-", separator)] = v[4..5] + v[2..3] + v[..1]
        data["#{k}-hex-r".gsub("-", separator)] = v[..1]
        data["#{k}-hex-g".gsub("-", separator)] = v[2..3]
        data["#{k}-hex-b".gsub("-", separator)] = v[4..5]
        data["#{k}-rgb-r".gsub("-", separator)] = v[..1].to_i(16)
        data["#{k}-rgb-g".gsub("-", separator)] = v[2..3].to_i(16)
        data["#{k}-rgb-b".gsub("-", separator)] = v[4..5].to_i(16)
        data["#{k}-dec-r".gsub("-", separator)] = v[..1].to_i(16)/255
        data["#{k}-dec-g".gsub("-", separator)] = v[2..3].to_i(16)/255
        data["#{k}-dec-b".gsub("-", separator)] = v[4..5].to_i(16)/255
      end
      data
    end

    def term_palette
      pal = ""
      palette.each do |_, v|
        pal += "  ".colorize.back(
          v[4..5].to_u8(16),
          v[2..3].to_u8(16),
          v[0..1].to_u8(16),
        ).to_s
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
  end

  def self.theme(name : String) : Theme
    tfile = DataFiles.get("/#{name}.yaml")
    Theme.from_yaml(tfile.gets_to_end)
  rescue BakedFileSystem::NoSuchFileError
    raise Exception.new("Theme not found: #{name}")
  end

end
