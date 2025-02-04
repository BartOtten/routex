![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)


# Routex: Supercharge your Phoenix Router

Routex is the most powerful routing library for Phoenix Framework. It is
designed to simplify route manipulation —giving developers unlimited control
over their app routes. Having a very custom need? Write your own extension
without having to know the nitty gritty details of the routing core.

Routex ships with *optional* extensions for internationalization, multilingual URLs,
route obfuscation, alternative routes generation and [many more](EXTENSION_SUMMARIES.md).

## Top Features and Benefits

* **No dependencies, no state**: Routex does not require any external dependency
  and works *by default* without proces state (e.g. no need for `Gettext.put_locale/1`).

* **Powerful transformations**: Routex supports advanced route transformations, including
  everything needed for internationalization (i18n) and localization (l10n).

* **Extension driven**: Being extension driven, Routex can be adapted to your
  specific needs. It's architecture allows you to write your own routing
  features without having to worry about breaking existing functionality. Routex
  ships with extensions covering a wide range of use cases.
  Have a look at [a summary of extensions](EXTENSION_SUMMARIES.md).

* **Optimized for performance**: Built to fit between route configuration and
route compilation. Routex enhances Phoenix routing without adding runtime
overhead, ensuring that applications run as fast as ever.

* **Detailed documentation**: Comprehensive, well-organized documentation
  provides clear guidance on installation, configuration, and best practices,
  making Routex approachable for developers at all levels. For example: If you
  are interested in internationalization (i18n) or localization (l10n) have a
  look at the [Localized Routes Tutorial](TUTORIAL_LOCALIZED_ROUTES.md).


## Demo

See Routex in action at the [official Routex Demo page](https://routex.fly.dev/).


## Requirements and Installation

See the [Usage Guide](USAGE.md) for the requirements and installation
instructions.


## Documentation

[HexDocs](https://hexdocs.pm/routex) (stable) and [GitHub
Pages](https://bartotten.github.io/routex) (development).


## Routex vs Cldr Routes vs Phoenix Router

`Phoenix`'s router (>= 1.8) and the use of the`:path_prefixes` option is by far
the easiest option. It adds prefixes to your routes for the well known
`/:language/products/` route format. Absolute basic, but buildin!

`Cldr Routes` adds the ability to use translated routes. It's main advantage is
also it's main disadvantage: being part of the Cldr suite ensure maximum
compatibility with that suite but also requires the (quite heavy) Cldr
dependency.

`Routex` is *[extension driven](EXTENSION_SUMMARIES.md)*. Routex boast the
widest, most dynamic feature scope and can be [easily extended](EXTENSIONS.md)
if the need arises. Like Phoenix' router, Routex minimizes necessity for code
modifications throughout your code base and does not add dependencies.
It's main advantage is the lack of limits: it makes every route transformation
and every route feature possible.

ps. If you use Cldr but rather use Routex for routing, see [the Cldr extension for
Routex](`Routex.Extension.Cldr`).


### Comparison table

| Feature             | Routex     | Cldr Routes | Phoenix >= 1.8 |
|---------------------|------------|-------------|----------------|
| Route encapsulation | Full  [^1] | Limited     | Limited        |
| Route manipulation  | Full  [^2] | Limited     | Limited        |
| Route interpolation | Full       | Limited     | Limited        |
| Alternative Routes  | Full       | Cldr        | Limited        |
| Verified Routes     | ☑          | ☑           | ☑              |
| Translation         | ☑          | ☑           | ☐              |
| Route Helpers       | ☑          | depr.       | depr.          |
| Drop-in replacement | ☑     [^3] | ☐           | -              |
| Standalone          | ☑          | ☐           | -              |
| Modular             | ☑          | ☐           | -              |
| Extendable          | ☑          | ☐           | -              |

[^1]: Routex' `preprocesss_using` is not bound to Phoenix (session) scopes  
[^2]: [Crazy example](https://hexdocs.pm/routex/Routex.Extension.Cloak.html)  
[^3]: *Optionally* Routex can be configured to shim original Phoenix functionality (for example: `~p` and `url/2`) or
mimick Cldr Routes using [an adapter extension](https://hexdocs.pm/routex/Routex.Extension.Cldr.html).
