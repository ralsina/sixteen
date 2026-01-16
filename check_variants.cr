#!/usr/bin/env crystal
require "./src/sixteen"

fixed = 0
total = 0

Sixteen.available_themes.each do |theme_name|
  begin
    theme = Sixteen.theme(theme_name)
    total += 1

    # Check if the variant matches the base00 color brightness
    base00 = theme.palette["base00"]
    is_dark = base00.dark?
    variant_is_dark = theme.variant == "dark"

    if is_dark != variant_is_dark
      puts "#{theme.name} (#{theme.slug}): variant is #{theme.variant} but base00 is #{base00.hex} (#{is_dark ? "dark" : "light"})"
      fixed += 1
    end
  rescue ex
    puts "Error loading #{theme_name}: #{ex.message}"
  end
end

puts "\nTotal themes: #{total}"
puts "Incorrect variants: #{fixed}"
