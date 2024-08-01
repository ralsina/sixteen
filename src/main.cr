require "./sixteen"
require "docopt"

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

puts HELP
