# 
![Logo of Routex](assets/logo_horizontal.png "Routex Logo")

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
  look at the [Localized Routes Guide](guides/LOCALIZED_ROUTES.md).


## Requirements and Installation

See the [Usage Guide](USAGE.md) for the requirements and installation
instructions.


## Online Demo

See Routex in action at the [official Routex Demo page](https://routex.fly.dev/).


## Documentation

[HexDocs](https://hexdocs.pm/routex) (stable) and [GitHub
Pages](https://bartotten.github.io/routex) (development).

## Routex compared to...
We published [a guide](COMPARISON.md) with the  intended to help you understand the differences, strengths,
and tradeoffs when deciding which routing solution best fits your needs.
