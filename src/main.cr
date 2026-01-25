require "./sixteen"
require "./template_file"
require "colorize"
require "docopt"
require "crystal_tui"

# Create a TUI app for theme browsing
class ThemeBrowser < Tui::App
  @names : Array(String)
  @list_view : Tui::ListView(String)
  @info_panel : Tui::Panel
  @info_vbox : Tui::VBox

  def initialize(@names : Array(String))
    super()

    list_w = @names.max_of(&.size) + 3

    # Create list view for themes
    @list_view = Tui::ListView(String).new("themes", @names)
    @list_view.constraints = Tui::Constraints.new(max_width: list_w)
    @list_view.selected_style = Tui::Style.new(fg: Tui::Color.black, bg: Tui::Color.red)
    @list_view.on_select do |name, _|
      update_info_panel(name)
    end

    @list_view.on_activate do |name, _|
      quit
      @selected_theme = name
    end

    # Create VBox for info content (will be populated dynamically)
    @info_vbox = Tui::VBox.new("info_content")

    # Create info panel
    @info_panel = Tui::Panel.new("Theme Info")
    @info_panel.content = @info_vbox

    # Initialize with first theme
    update_info_panel(@names.first) unless @names.empty?
  end

  property selected_theme : String? = nil

  def update_info_panel(name : String) : Nil
    theme = Sixteen.theme(name)

    # Clear existing children
    @info_vbox.clear_children

    # Create and add new labels
    labels = [] of Tui::Widget

    # Add theme info labels
    labels << Tui::Label.new("Name: #{theme.name}", fg: Tui::Color.white)
    labels << Tui::Label.new("Author: #{theme.author}", fg: Tui::Color.white)

    unless theme.description.empty?
      labels << Tui::Label.new("Description: #{theme.description}", fg: Tui::Color.white)
    end

    unless theme.variant.empty?
      labels << Tui::Label.new("Variant: #{theme.variant}", fg: Tui::Color.white)
    end

    labels << Tui::Label.new("") # spacer

    # Add color palette
    sorted_keys = theme.palette.keys.sort!
    sorted_keys.each do |key|
      color = theme[key]
      contrast = theme.contrasting(key.lchop("base").to_i(base: 16))

      # Create a label with the color name and hex value
      label_text = "#{key}: #{color.hex}"
      label = Tui::Label.new(label_text,
        fg: Tui::Color.rgb(contrast.r.to_i, contrast.g.to_i, contrast.b.to_i),
        bg: Tui::Color.rgb(color.r.to_i, color.g.to_i, color.b.to_i))
      # Set max height to 1 line
      label.constraints = Tui::Constraints.new(max_height: 1)
      labels << label
    end

    # Add all labels as children
    labels.each { |label| @info_vbox.add_child(label) }

    mark_dirty!
  end

  def compose : Array(Tui::Widget)
    # Use HBox for split layout
    hbox = Tui::HBox.new("main") do
      [@list_view.as(Tui::Widget), @info_panel.as(Tui::Widget)]
    end

    [hbox] of Tui::Widget
  end

  def handle_event(event : Tui::Event) : Bool
    if event.is_a?(Tui::KeyEvent)
      # Quit on q or Ctrl+C
      if event.matches?("q") || event.matches?("ctrl+c")
        quit
        return true
      end

      # Vim-style navigation
      if event.matches?("j") || event.matches?("down")
        @list_view.select_next
        return true
      elsif event.matches?("k") || event.matches?("up")
        @list_view.select_prev
        return true
      elsif event.matches?("enter")
        item = @list_view.selected_item
        if item
          @selected_theme = item
          quit
        end
        return true
      end
    end

    super
  end
end

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
    template.render(scheme, scheme_name)
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
    get_theme_with_variant(scheme_name, options)
    context = Sixteen.theme_with_family_context(scheme_name)
    puts Crustache.render(
      Crustache.parse(File.read(template)),
      context
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

  # Get theme names
  names = Sixteen::DataFiles.files.select { |fname|
    fname.path.ends_with?(".yaml")
  }.map { |fname|
    File.basename(fname.path, ".yaml")
  }.sort!

  # Run the browser
  browser = ThemeBrowser.new(names)
  browser.run

  # Print selected theme name
  if theme_name = browser.selected_theme
    puts theme_name
  end

  exit 0
end

puts HELP
