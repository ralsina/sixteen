require "./spec_helper"
require "file_utils"
require "../src/template_file"

module Sixteen
  describe TemplateFile do
    describe "#filename" do
      it "returns the explicit filename when set" do
        file = TemplateFile.from_yaml("---\nfilename: out.conf\n")
        file.filename.should eq "out.conf"
      end

      it "builds a default filename from output and extension" do
        file = TemplateFile.from_yaml("---\noutput: ~/.config/foo\nextension: conf\n")
        file.filename.should eq "~/.config/foo/{{scheme-system}}-{{scheme-slug}}.conf"
      end

      it "strips leading dots from the extension" do
        file = TemplateFile.from_yaml("---\noutput: /tmp/x\nextension: .json\n")
        file.filename.should eq "/tmp/x/{{scheme-system}}-{{scheme-slug}}.json"
      end

      it "raises when neither filename nor output+extension are set" do
        file = TemplateFile.from_yaml("---\n{}\n")
        expect_raises(Exception, "Template has no filename and no output and extension") do
          file.filename
        end
      end
    end
  end

  describe Template do
    it "loads config.yaml entries from a template folder" do
      dir = File.tempname("sixteen-template-test")
      Dir.mkdir(dir)
      begin
        File.write("#{dir}/config.yaml", <<-YAML)
          colorscheme:
            filename: generated-theme.conf
          another:
            output: /out
            extension: txt
          YAML
        template = Sixteen.template(dir)
        template.keys.should eq ["colorscheme", "another"]
      ensure
        FileUtils.rm_r(dir)
      end
    end
  end
end
