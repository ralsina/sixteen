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
  Sixteen::DataFiles.files.map { |f|
    "  * #{File.basename(f.path, ".yaml")}"
  }.sort!.each { |p|
    puts p
  }
  exit 0
end

if options["--info"]
  scheme = options["<scheme>"].as(String)
  puts "Scheme: #{scheme}"
  puts Sixteen.theme(scheme).to_s
  exit 0
end

if options["--build"]
  template = Sixteen.template options["<template>"].as(String)
  scheme = Sixteen.theme options["<scheme>"].as(String)
  puts "Building theme from #{scheme} using #{template}"
  exit 0
end

puts HELP
