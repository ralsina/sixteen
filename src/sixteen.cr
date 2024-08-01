require "baked_file_system"
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
    property palette : Hash(String, String)
  end

  def self.theme(name : String) : Theme
    tfile = DataFiles.get("/#{name}.yaml")
    Theme.from_yaml(tfile.gets_to_end)
  rescue BakedFileSystem::NoSuchFileError
    raise Exception.new("Theme not found: #{name}")
  end
end
