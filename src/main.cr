require "./sixteen"
require "colorize"
require "docopt"
require "lime"

HELP = <<-DOCOPT
Sixteen: a Tinted Themes builder

It combines a templated as defined in the Tinted Themes
specification with a color scheme to generate a theme file.

Usage:
  sixteen (-h | --help)
  sixteen --list
  sixteen --info <scheme>
  sixteen --build <template> <scheme>
  sixteen --render <template> <scheme>
  sixteen --version
  sixteen --interactive

Options:
    -h --help       Show this screen.
    --list          List available schemes.
    --info          Show information about a scheme.
    --build         Build theme files from a tinted themes style template folder and a scheme.
    --render        Render a mustache template with a scheme and
    --interactive   Show an interactive menu to look at themes.
    --version       Show version.
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

if options["--render"]
  template = options["<template>"].as(String)
  scheme = Sixteen.theme options["<scheme>"].as(String)
  puts Crustache.render(
    Crustache.parse(File.read(template)),
    scheme.context
  )
  exit 0
end

if options["--interactive"]
  names = Sixteen::DataFiles.files.select { |fname|
    fname.path.ends_with?(".yaml")
  }.map { |fname|
    File.basename(fname.path, ".yaml")
  }.sort!
  list_w = names.max_of(&.size) + 4
  offset = 0
  current = 0
  k = ""
  STDIN.noecho do
    Lime.loop do

      # Get some sizes we need
      # Window.update
      wh = Window.height
      ww = Window.width
      max_tw = ww - list_w - 2


      # Draw the list of themes on the left
      visible_names = names[offset..offset + wh]
      visible_names.each_with_index do |name, i|
        if current == i + offset
          Lime.print ">>#{name}".ljust(list_w).colorize(:red).mode(:bold), 0, i
        else
          Lime.print "  #{name}".ljust(list_w), 0, i
        end
      end

      # Draw the current theme info on the right
      theme = Sixteen.theme(names[current])
      Lime.print "Name: #{theme.name}"[...max_tw].colorize(:white), list_w, 1
      Lime.print "Author: #{theme.author}"[...max_tw].colorize(:white), list_w, 2
      Lime.print "Description: #{theme.description}"[...max_tw].colorize(:white), list_w, 3 unless theme.description.empty?
      Lime.print "Variant: #{theme.variant}"[...max_tw].colorize(:white), list_w, 3 unless theme.variant.empty?
      theme.palette.keys.sort!.each_with_index { |key, i|
        break if 6 + i > wh
        color = theme.palette[key]
        r = color[0...2].to_u8(16)
        g = color[2...4].to_u8(16)
        b = color[4...6].to_u8(16)
        Lime.print "#{key}:", list_w, 6 + i
        Lime.print (" "*(max_tw - 10)).colorize.back(r, g, b), list_w + 9, 6 + i
      }
      Lime.draw
      k = Lime.get_key
      case k
      when "j", :up
        current -= 1 unless current == 0
        offset -= 1 if current < offset
      when "k", :down
        current += 1 unless current == names.size - 1
        offset += 1 if current - offset > wh
      when :enter
        puts names[current]
        exit 0
      when :ctrl_c, "q"
        break
      end
    end
  end
  exit 0
end

puts HELP
