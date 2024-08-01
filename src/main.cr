require "./sixteen"

puts Sixteen::DataFiles.files.map &.path

puts Sixteen.theme("tokyo-night-dark").slug
