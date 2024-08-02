# Sixteen

Sixteen is a Crystal library to access Base-16 theme data.

It embeds the whole base16 theme set, so you can use it in your applications without having to track things down and carry them
around (the bad news: it adds about .5MB to your binary).

The API is not defined yet, it will grow as I use it in other
projects (I am not doing this for fun, I am doing it because I need it 🤣)

For more information on base16, check [Tinted Theming](https://github.com/tinted-theming/home)

As a bonus, this creates a binary, called `sixteen` that can
render templates using the themes.

```
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
```

The interactive mode shows the themes and gives you some information about them.

[![asciicast](https://asciinema.org/a/iUKp8SyZEC3OHTByi8lLNY8Zf.svg)](https://asciinema.org/a/iUKp8SyZEC3OHTByi8lLNY8Zf)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     sixteen:
       github: ralsina/sixteen
   ```

2. Run `shards install`

## Usage

```crystal
require "sixteen"
```

You can get a `Sixteen::Theme` object by name:

```crystal
Sixteen.theme("unikitty-dark")
```

You can get a template (in the Tinting Themes sense) parsed
by path, and render it by passing a theme (be *very* careful
about where the output goes!)

```crystal
template = Sixteen.template("i3")
template.render(Sixteen.theme("unikitty-dark"))
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/ralsina/sixteen/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Roberto Alsina](https://github.com/ralsina) - creator and maintainer
- Themes are from [Tinted Theming](https://github.com/tinted-theming)
  and written by dozens of people (each theme has individual
  credits!)
