#!/usr/bin/env crystal
require "json"
require "crustache"

SCRIPT_DIR = __DIR__
data = JSON.parse(File.read(File.join(SCRIPT_DIR, "..", "site", "index.json")))

families = data.as_a.map do |family|
  themes = family["themes"].as_a

  # Get the first theme as the primary one for display
  primary_theme = themes.first

  name = primary_theme["name"].as_s
  author = primary_theme["author"].as_s
  slug = primary_theme["slug"].as_s
  palette = primary_theme["palette"].as_a.map(&.as_s)

  swatches = palette.map { |color| "<span class=\"palette-swatch\" style=\"background-color: #{color};\"></span>" }.join

  # Build variant badges
  variant_badges = themes.map do |theme|
    variant = theme["variant"].as_s
    case variant
    when "dark"  then "<small class='variant-badge variant-dark'>dark</small>"
    when "light" then "<small class='variant-badge variant-light'>light</small>"
    else              "<small class='variant-badge'>#{variant}</small>"
    end
  end

  # Add auto-generated indicator if family only has one variant
  has_auto = themes.size == 1
  auto_indicator = has_auto ? " <small class='auto-indicator'>(auto #{themes.first["variant"].as_s == "dark" ? "light" : "dark"} available)</small>" : ""

  <<-ROW
  <tr class="theme-row" onclick="window.location='#{slug}/index.html'">
    <td>
      <strong>#{name}</strong>
      <div class="variants">#{variant_badges.join("")}#{auto_indicator}</div>
    </td>
    <td>
      <div class="palette">
        #{swatches}
      </div>
    </td>
    <td><small>#{author}</small></td>
  </tr>
  ROW
end

# Update header
template = Crustache.parse(File.read(File.join(SCRIPT_DIR, "index.html.mustache")))

puts Crustache.render(template, {"families" => families})
