require "./sixteen"
require "./template_file"
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
  sixteen --info <scheme> [--light | --dark]
  sixteen --build <template> <scheme> [--light | --dark]
  sixteen --render <template> <scheme> [--light | --dark]
  sixteen --families
  sixteen --version
  sixteen --interactive

Options:
    -h --help       Show this screen.
    --list          List available schemes.
    --info          Show information about a scheme.
    --build         Build theme files from a tinted themes style template folder and a scheme.
    --render        Render a mustache template with a scheme and
    --families      Show theme families (dark/light variant groups).
    --light         Use light variant of the specified theme.
    --dark          Use dark variant of the specified theme.
    --interactive   Show an interactive menu to look at themes.
    --version       Show version.
DOCOPT

options = Docopt.docopt(HELP, ARGV)

# Handle version manually
if options["--version"]
  puts "Sixteen #{Sixteen::VERSION}"
  exit 0
end

# Helper function to get theme with variant
def get_theme_with_variant(scheme_name : String, opts) : Sixteen::Theme
  if opts["--light"]
    Sixteen.light_variant(scheme_name)
  elsif opts["--dark"]
    Sixteen.dark_variant(scheme_name)
  else
    # Try with fallback for base name lookup
    begin
      Sixteen.theme(scheme_name)
    rescue
      Sixteen.theme_with_fallback(scheme_name)
    end
  end
end

if options["--list"]
  puts "Available schemes:"
  Sixteen::DataFiles.files.select { |fname|
    fname.path.ends_with?(".yaml")
  }.map { |fname|
    "  * #{File.basename(fname.path, ".yaml")}"
  }.sort!.each { |name|
    puts name
  }
  exit 0
end

if options["--info"]
  scheme = options["<scheme>"].as(String)
  begin
    theme = get_theme_with_variant(scheme, options)
    puts theme.to_s
    exit 0
  rescue Exception
    STDERR.puts "Error: Theme not found: #{scheme}"
    exit 1
  end
end

if options["--build"]
  template = Sixteen.template options["<template>"].as(String)
  scheme_name = options["<scheme>"].as(String)
  begin
    scheme = get_theme_with_variant(scheme_name, options)
    template.render(scheme)
    exit 0
  rescue Exception
    STDERR.puts "Error: Theme not found: #{scheme_name}"
    exit 1
  end
end

if options["--render"]
  template = options["<template>"].as(String)
  scheme_name = options["<scheme>"].as(String)
  begin
    scheme = get_theme_with_variant(scheme_name, options)
    puts Crustache.render(
      Crustache.parse(File.read(template)),
      scheme.context
    )
    exit 0
  rescue Exception
    STDERR.puts "Error: Theme not found: #{scheme_name}"
    exit 1
  end
end

if options["--families"]
  puts "Theme families (dark/light variant groups):"
  puts

  families = Sixteen.theme_families.select { |family|
    !family.dark_themes.empty? && !family.light_themes.empty?
  }.sort_by!(&.base_name)

  families.each do |family|
    puts "#{family.base_name}:"
    puts "  Dark themes: #{family.dark_themes.join(", ")}" unless family.dark_themes.empty?
    puts "  Light themes: #{family.light_themes.join(", ")}" unless family.light_themes.empty?
    puts unless family == families.last?
  end

  puts "\nTotal families with both variants: #{families.size}"
  exit 0
end

if options["--interactive"]
  if Sixteen::DataFiles.files.empty?
    puts "This binary was built with no embedded themes, so no interactive mode is available."
    exit 1
  end
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
        color = theme[key]
        Lime.print "#{key}:", list_w, 6 + i
        contrast = theme.contrasting(i)
        Lime.print theme[key].hex.ljust(max_tw - 10).colorize(contrast.colorize).back(color.colorize), list_w + 9, 6 + i
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
