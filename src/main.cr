require "./sixteen"
require "colorize"
require "docopt"
require "lime"

HELP = <<-DOCOPT
Sixteen: a Timted Themes builder

It combines a templated as defined in the Tinted Themes
specification with a color scheme to generate a theme file.

Usage:
  sixteen (-h | --help)
  sixteen --list
  sixteen --info <scheme>
  sixteen --build <template> <scheme>
  sixteen --version
  sixteen --interactive

Options:
    -h --help     Show this screen.
    --list        List available schemes.
    --info        Show information about a scheme.
    --build       Build theme files from a template and a scheme.
    --version     Show version.
DOCOPT

options = Docopt.docopt(HELP, ARGV)

# Handle version manually
if options["--version"]
  puts "Crycco #{Sixteen::VERSION}"
  exit 0
end

if options["--list"]
  puts "Available schemes:"
  Sixteen::DataFiles.files.map { |fname|
    "  * #{File.basename(fname.path, ".yaml")}"
  }.sort!.each { |name|
    puts name
  }
  exit 0
end

if options["--info"]
  scheme = options["<scheme>"].as(String)
  puts Sixteen.theme(scheme).to_s
  exit 0
end

if options["--build"]
  template = Sixteen.template options["<template>"].as(String)
  scheme = Sixteen.theme options["<scheme>"].as(String)
  template.render(scheme)
  exit 0
end

if options["--interactive"]
  names = Sixteen::DataFiles.files.map { |fname|
    " #{File.basename(fname.path, ".yaml")}"
  }.sort!
  offset = 0
  current = 0
  k = ""
  STDIN.noecho do
    Lime.loop do
      # Lime.clear
      wh = Window.height
      visible_names = names[offset..offset + wh]
      visible_names.each_with_index do |name, i|
        if current == i + offset
          Lime.print ">>#{name}".colorize.green.bold, 0, i
        else
          Lime.print "  #{name}", 0, i
        end
      end
      Lime.draw
      # sleep 0.1.seconds
      k = Lime.get_key
      case k
      when "j", :up
        current -= 1 unless current == 0
        offset -= 1 if current < offset
      when "k", :down
        current += 1 unless current == names.size - 1
        offset += 1 if current - offset > wh
      when :ctrl_c, "q"
        break
      end
    end
  end
  exit 0
end

puts HELP
