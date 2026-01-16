#!/usr/bin/env crystal
require "json"

SCRIPT_DIR = File.dirname(__FILE__).empty? ? "." : File.dirname(__FILE__)
data = JSON.parse(File.read(File.join(SCRIPT_DIR, "index.json")))

template = File.read(File.join(SCRIPT_DIR, "index.html.mustache"))

rows = data.as_a.map do |family|
  base_name = family["base_name"].as_s
  themes = family["themes"].as_a

  # Get the first theme as the primary one for display
  primary_theme = themes.first

  name = primary_theme["name"].as_s
  author = primary_theme["author"].as_s
  slug = primary_theme["slug"].as_s
  palette = primary_theme["palette"].as_a.map(&.as_s)

  swatches = palette.map { |color| "<span class=\"palette-swatch\" style=\"background-color: #{color};\"></span>" }.join

  # Build variant badges
  variant_badges = themes.map do |t|
    variant = t["variant"].as_s
    case variant
    when "dark"  then "<small class='variant-badge variant-dark'>dark</small>"
    when "light" then "<small class='variant-badge variant-light'>light</small>"
    else              "<small class='variant-badge'>#{variant}</small>"
    end
  end.join(" ")

  # Add auto-generated indicator if family only has one variant
  has_auto = themes.size == 1
  auto_indicator = has_auto ? " <small class='auto-indicator'>(auto #{themes.first["variant"].as_s == "dark" ? "light" : "dark"} available)</small>" : ""

  <<-ROW
        <tr class="theme-row" onclick="window.location='#{slug}/index.html'">
          <td>
            <strong>#{name}</strong>
            <div class="variants">#{variant_badges}#{auto_indicator}</div>
          </td>
          <td><small>#{author}</small></td>
          <td>
            <div class="palette">
              #{swatches}
            </div>
          </td>
        </tr>
  ROW
end.join

# Update header
family_count = data.as_a.size
theme_count = data.as_a.sum { |f| f["themes"].as_a.size }
header = "<h1>Sixteen Showcase</h1>\n    <p>#{family_count} theme families, #{theme_count} themes</p>"

rendered = template.gsub("{{#themes}}", "").gsub("{{/themes}}", "").gsub("{{#themes}}", "").gsub("{{name}}", "").gsub("{{author}}", "").gsub("{{slug}}", "").gsub("{{#palette}}", "").gsub("{{/palette}}", "").gsub("{{.}}", "")
rendered = rendered.sub(/<h1>.*<\/p>/m, header)
rendered = rendered.sub(/<tbody>.*<\/tbody>/m, "<tbody>\n#{rows}\n      </tbody>")

puts rendered
