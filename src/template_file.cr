require "crustache"

module Sixteen
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
