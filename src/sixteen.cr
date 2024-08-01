require "baked_file_system"
require "colorize"
require "crustache"
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

    def context
      data = Hash(String, Bool | String | Int32 | Float64).new

      data["scheme-name"] = name
      data["scheme-author"] = author
      data["scheme-description"] = description
      data["scheme-slug"] = slug
      data["scheme-slug-underscored"] = slug.gsub("-", "_")
      data["scheme-system"] = system
      data["scheme-variant"] = variant
      data["scheme-is-#{variant}-variant"] = true
      palette.each do |k, v|
        data["#{k}-hex"] = v
        data["#{k}-hex-bgr"] = v[4..5] + v[2..3] + v[..1]
        data["#{k}-hex-r"] = v[..1]
        data["#{k}-hex-g"] = v[2..3]
        data["#{k}-hex-b"] = v[4..5]
        data["#{k}-rgb-r"] = v[..1].to_i(16)
        data["#{k}-rgb-g"] = v[2..3].to_i(16)
        data["#{k}-rgb-b"] = v[4..5].to_i(16)
        data["#{k}-dec-r"] = v[..1].to_i(16)/255
        data["#{k}-dec-g"] = v[2..3].to_i(16)/255
        data["#{k}-dec-b"] = v[4..5].to_i(16)/255
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

  struct TemplateFile
    include YAML::Serializable
    property systems : Array(String) = ["base16"]
    property filename : String?
    property extension : String?
    property output : String?

    def filename : String?
      return @filename unless @filename.nil?
      raise Exception.new(
        "Template has no filename and no output and extension"
      ) if output.nil? || extension.nil?
      "#{output}/{{scheme-system}}-{{scheme-slug}}.#{extension.as(String).lstrip(".")}"
    end
  end

  class Template < Hash(String, TemplateFile)
    property path : String

    def initialize(@path)
      super()
      @path = path
      parsed = Hash(String, TemplateFile).from_yaml(File.read("#{path}/config.yaml"))
      self.merge!(parsed)
    end

    def render(theme : Theme)
      context = theme.context
      self.each do |k, v|
        fname = Crustache.render(
          Crustache.parse(v.filename.as(String)), context)
        FileUtils.mkdir_p(File.dirname fname)
        puts "Rendering #{fname} from #{path}/#{k}.mustache"
        File.open(fname, "w") do |outf|
          outf << Crustache.render(
            Crustache.parse(File.read("#{path}/#{k}.mustache")), context)
        end
      end
    end
  end

  def self.template(path : String) : Template
    Template.new(path)
  end
end
