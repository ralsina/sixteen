# Sixteen

Sixteen is a Crystal library to access Base-16 theme data.

It embeds the whole base16 theme set (300+ themes), so you can use it in your
applications without having to track things down and carry them
around (the bad news: it adds about .6MB to your binary).

For more information on base16, check [Tinted Theming](https://github.com/tinted-theming/home)

As a bonus, this creates a binary, called `sixteen` that can
render templates using the themes.

```docopt
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
    --build         Build theme files from a tinted themes style
                    template folder and a scheme.
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

Or just use the colors directly:

```crystal
theme = Sixteen.theme("unikitty-dark")
puts theme["base00"].hex  # 212a31
puts theme[0].r    # 33
```

## Choosing what themes you want

By default Sixteen will provide all the themes by embedding them in the binary.
This makes the binary large! If you are using sixteen as a library, you may
want to include just a few themes. To do that:

* Pass the `-Dnothemes` flag to the compiler
* Set the `SIXTEEN_THEMES` environment variable to a comma-separated
  list of themes you want to include.

This builds the theme browser with only the horizon-dark and horizon-light themes:

```bash
SIXTEEN_THEMES=horizon-dark,horizon-light shards build -Dnothemes
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
