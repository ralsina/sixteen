# Sixteen

Sixteen is a Crystal library to access Base-16 theme data.

It embeds the whole base16 theme set, so you can use it in your applications without having to track things down and carry them
around (the bad news: it adds about .5MB to your binary).

The API is not defined yet, it will grow as I use it in other
projects (I am not doing this for fun, I am doing it because I need it 🤣)

For more information on base16, check [Tinted Theming](https://github.com/tinted-theming/home)

As a bonus, this creates a binary, called `sixteen` that can
render templates using the themes. You probably don't want to
use it for anything ;-)

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
