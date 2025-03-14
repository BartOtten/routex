# 
![Logo of Routex](assets/logo_horizontal.png "Routex Logo")

![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)

# Routex: Phoenix localized routes and beyond...

Routex is a robust routing library that integrates seamlessly with Phoenix
Router, providing a comprehensive solution for even the most complex routing
requirements. It streamlines route manipulation so that you have complete
control over your application's navigation logic.

Designed with extensibility in mind, Routex comes equipped with a suite of
extensions—covering internationalization (i18n), localization (l10n),
multilingual URL handling, alternative route generation, and more (see
[Extension Summaries](docs/EXTENSION_SUMMARIES.md) for details). Its modern
architecture makes it straightforward to craft custom routing solutions that
integrate effortlessly with other extensions.

<p class="hidden-at-hexdocs">
  This documentation reflects the main branch. For the latest stable release,
  refer to <a href="https://hexdocs.pm/routex/readme.html">HexDocs</a>.
</p>

## Top Features and Benefits

- **Zero Dependencies & Stateless Operation:** Routex is unique in not depending
  on external dependencies and functions out-of-the-box without requiring
  process state.

- **Runtime Integrations:** Routex extensions can provide tailor made Plugs and
  Phoenix LiveView Lifecycle Hooks; bridging the gap between server-side routing
  and client-side interactivity.

- **Advanced Route Transformations:** It supports sophisticated route
  transformations to not only to cover every aspect of internationalization (i18n)
  and localization (l10n) and go beyond.

- **Extension-Centric Design:** The extension-driven architecture of Routex
  allows you to tailor its behavior to meet your specific needs. Customize
  routing features without worrying about breaking existing functionality—see
  [Extension Summaries](docs/EXTENSION_SUMMARIES.md) for a full list.

- **Optimized Performance:** Positioned between route configuration and
  compilation, Routex enhances Phoenix routing without adding runtime overhead.

- **Comprehensive Documentation:** Detailed and well-organized guides provide
  clear instructions for installation, configuration, and best practices, making
  Routex accessible to developers at every level. For specialized topics like
  i18n or l10n, consult the [Localized Routes
  Guide](docs/guides/LOCALIZED_ROUTES.md).


## Articles

To help you understand where Routex fits in.

### [How Routex and Phoenix Router Work Together](docs/ROUTEX_AND_PHOENIX_ROUTER.md)
Understanding how Routex, its extensions, and Phoenix Router work together can
be tricky at first sight. To help you understand, we came up with an analogy.

### [Routex compared to Phoenix Router and Cldr Routes](docs/COMPARISON.md)
We published a comparison with the intended to help you understand
the differences, strengths, and tradeoffs when deciding which routing solution
best fits your needs.


## Installation and usage

**[Usage Guide](USAGE.md)** - requirements and installation.
instructions.

**[Documentation](https://hexdocs.pm/routex)** - from step-by-step guides till in-depth explanations.


## Give it a try!
**[Online demo](https://routex.fly.dev/)** - have a look or get the
[code](https://github.com/BartOtten/routex_example/).


