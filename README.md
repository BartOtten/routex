# 
![Logo of Routex](assets/logo_horizontal.png "Routex Logo")

![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)

# Routex: Supercharge your Phoenix Router

This powerful library works together with Phoenix Router to provide the ultimate
routing solution. It simplifies route manipulation, giving you the control you
need to handle even the most demanding routing requirements.

Routex comes with extensions for internationalization (i18n), localization
(l10n), translated (multilingual) URLs, alternative routes generation and [many
more](EXTENSION_SUMMARIES.md). Its modern extensible architecture enables you to easily
build custom solutions that work harmoniously with other extensions.

## Top Features and Benefits

* **No dependencies, no state**: Routex is unique in not requiring any external dependency
  and works *by default* without proces state.

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


## Installation and usage

**[Usage Guide](USAGE.md)** - requirements and installation.
instructions.

**[Documentation](https://hexdocs.pm/routex)** - from step-by-step guides till in-depth explanations.


## Give it a try!
**[Online demo](https://routex.fly.dev/)** - have a look or get the
[code](https://github.com/BartOtten/routex_example/).


## Articles

To help you understand where Routex fits in.

### [How Routex and Phoenix Router Work Together](ROUTEX_AND_PHOENIX_ROUTER.md)
Understanding how Routex, its extensions, and Phoenix Router work together can
be tricky at first sight. To help you understand, we came up with an anology.

### [Routex compared to Phoenix Router and Cldr Routes](COMPARISON.md)
We published a comparison with the intended to help you understand
the differences, strengths, and tradeoffs when deciding which routing solution
best fits your needs.
