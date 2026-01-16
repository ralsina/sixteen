#!/usr/bin/env crystal
require "crustache"
require "./src/sixteen"

OUTPUT_DIR     = "site"
TEMPLATE_DIR   = "site_showcase"
THEME_TEMPLATE = File.read(File.join(TEMPLATE_DIR, "theme.html.mustache"))
CSS_TEMPLATE   = File.read(File.join(TEMPLATE_DIR, "theme.css.mustache"))

# Don't remove the directory - it was already created by the shell script
# and contains the index files
Dir.mkdir_p(OUTPUT_DIR)

generated = Set(String).new
themes = Sixteen.available_themes

puts "Generating #{themes.size} themes + auto-variants..."

# Track which families have both variants to avoid duplicate auto-generation
families_with_both = Set(String).new

# First pass: check which families have both variants
themes.each do |theme_name|
  begin
    theme = Sixteen.theme(theme_name)
    family = Sixteen.theme_family_info(theme_name)

    # Check if family has both dark and light (excluding auto-generated)
    has_real_light = family.light_themes.none?(&.includes?("-auto-"))
    has_real_dark = family.dark_themes.none?(&.includes?("-auto-"))

    if has_real_light && has_real_dark
      families_with_both << theme.slug
    end
  rescue
  end
end

# Second pass: generate themes
themes.each do |theme_name|
  theme = Sixteen.theme(theme_name)

  # Generate this theme
  slug = theme.slug.empty? ? theme.name.downcase.gsub(" ", "-") : theme.slug
  generate_theme(theme, slug, theme_name, generated)

  # Generate auto-variant only if family doesn't have both variants
  unless families_with_both.includes?(theme.slug)
    if theme.variant == "dark"
      auto_light = theme.invert_for_theme(:light)
      auto_slug = auto_light.slug.empty? ? auto_light.name.downcase.gsub(" ", "-") : auto_light.slug
      generate_theme(auto_light, auto_slug, theme_name, generated)
    elsif theme.variant == "light"
      auto_dark = theme.invert_for_theme(:dark)
      auto_slug = auto_dark.slug.empty? ? auto_dark.name.downcase.gsub(" ", "-") : auto_dark.slug
      generate_theme(auto_dark, auto_slug, theme_name, generated)
    end
  end
end

puts "Done! Generated #{generated.size} theme pages in #{OUTPUT_DIR}/"

def generate_theme(theme : Sixteen::Theme, slug : String, theme_name : String, generated : Set(String))
  return if generated.includes?(slug)

  theme_dir = File.join(OUTPUT_DIR, slug)
  Dir.mkdir_p(theme_dir)

  # Get context with family info
  context = Sixteen.theme_with_family_context(theme_name)

  # Override values for auto-generated themes
  if slug.includes?("-auto-")
    context["scheme-name"] = theme.name
    context["scheme-author"] = theme.author
    context["scheme-slug"] = slug

    # Update color palette with auto-generated theme's colors
    theme_context = theme.context("-")
    theme_context.each do |key, value|
      if key.starts_with?("base")
        context[key] = value
      end
    end

    # For auto-generated themes, add the original theme to family navigation
    base_slug = slug.sub("-auto-light", "").sub("-auto-dark", "")
    if slug.includes?("-auto-light")
      # This is an auto-light theme, so show the original dark theme
      context["family-other-dark"] = base_slug
      context.delete("family-other-light")
    elsif slug.includes?("-auto-dark")
      # This is an auto-dark theme, so show the original light theme
      context["family-other-light"] = base_slug
      context.delete("family-other-dark")
    end
  end

  # Render HTML and CSS
  rendered_html = Crustache.render(Crustache.parse(THEME_TEMPLATE), context)
  rendered_css = Crustache.render(Crustache.parse(CSS_TEMPLATE), context)

  File.write(File.join(theme_dir, "index.html"), rendered_html)
  File.write(File.join(theme_dir, "theme.css"), rendered_css)

  generated.add(slug)
  puts "  #{slug}"
end

def find_theme_name_for_slug(slug : String) : String
  # For auto-generated themes, extract the base slug
  if slug.includes?("-auto-dark")
    base_slug = slug.sub("-auto-dark", "")
    return find_theme_by_slug(base_slug)
  elsif slug.includes?("-auto-light")
    base_slug = slug.sub("-auto-light", "")
    return find_theme_by_slug(base_slug)
  end

  # Try to find theme by slug
  find_theme_by_slug(slug)
end

def find_theme_by_slug(slug : String) : String
  themes = Sixteen.available_themes
  themes.each do |theme_name|
    begin
      theme = Sixteen.theme(theme_name)
      return theme_name if theme.slug == slug
    rescue
    end
  end

  # Fallback: try exact match
  if themes.includes?(slug)
    return slug
  end

  # Last resort: return the slug itself
  slug
end
