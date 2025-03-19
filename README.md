# 
![Logo of Routex](assets/logo_horizontal.png "Routex Logo")

![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)

# Routex: Phoenix route localization and beyond....

Routex is a powerful library designed to work seamlessly with Phoenix Router,
providing an unparalleled routing solution. It simplifies route manipulation,
giving you the control you need to handle even the most demanding routing
requirements.

Routex comes with a suite of extensions tailored for internationalization
(i18n) and localization (l10n), including support for translated (multilingual)
URLs and alternative route generation. Its modern, extensible architecture
allows you to effortlessly build custom solutions that integrate smoothly with
other extensions, extending its capabilities far beyond just localization.

Whether you need to create multilingual URLs, manage alternative routes, or
build custom routing solutions, Routex offers the flexibility and power you
need to enhance your Phoenix applications.

<p class="hidden-at-hexdocs">
This documentation reflects the main branch. For the latest
stable release, refer to [Hexdocs](https://hexdocs.pm/routex/readme.html).
</p>


## Benefits and Features:

* **Comprehensive Internationalization:** Built-in support for both
  internationalization (i18n) and localization (l10n) allows you to create fully
  translated, multilingual URLs effortlessly.

* **Runtime Behavior**:Seamlessly blend compile-time code generation with
  dynamic runtime behavior through hooks and plugs conveniently provided by
  extensions.

* **Optimized Performance:** Positioned between route configuration and
  compilation, Routex enhances Phoenix routing without incurring additional
  runtime costs.

* **No dependencies, no state**: Routex is unique in not relying on external
  dependency and works out-of-the-box without proces state.

* **Detailed documentation**: Comprehensive, well-organized documentation
  provides clear guidance on installation, configuration, and best practices,
  making Routex approachable for developers at all levels. For example: If you
  are interested in internationalization (i18n) or localization (l10n) have a
  look at the [Localized Routes Guide](docs/guides/LOCALIZED_ROUTES.md).


## Give it a try!

**[Online demo](https://routex.fly.dev/)** - have a look or get the
[code](https://github.com/BartOtten/routex_example/).


## Installation and usage

**[Usage Guide](USAGE.md)** - requirements and installation.
instructions.

**[Documentation](https://hexdocs.pm/routex)** - from step-by-step guides till in-depth explanations.


## Knowledge Base

To better understand how Routex integrates with Phoenix Router and where it fits
into the broader ecosystem, take a look at our in-depth guides:

**[How Routex and Phoenix Router Work Together](docs/ROUTEX_AND_PHOENIX_ROUTER.md)** - 
Discover the mechanics behind the integration and the benefits of a unified routing system.

**[Routex compared to Phoenix Router and Cldr Routes](docs/COMPARISON.md)** - 
Understand the differences, strengths, and tradeoffs when deciding which
routing solution best fits your needs.


## Extensions

Routex comes equipped with a extensions that cater to common and advanced use
cases in Phoenix applications. Each extension is designed to operate
independently yet harmoniously with other extensions through the shared
`Routex.Attrs` system. This flexibility allows you to tailor your routing system
to your specific needs without resorting to extensive modifications or the
burden of maintaining a fork.

### Benefits:
- **Modularity**: Each feature is encapsulated in its own extension, making
  it easier to manage and maintain.
- **Flexibility**: Extensions can be enabled or disabled as needed, allowing
  for a customizable and adaptable routing system.
- **Interoperability**: By using `Routex.Attrs` to share attributes, extensions
  can work together seamlessly without being tightly coupled, promoting a
  decoupled and scalable architecture.
- **Customizability**: If you have a unique requirement, you can adapt an
  existing extension -or create your own- without the need to fork or reach
  upstream consensus on the need and purpose.

### Index
- [Alternatives](docs/guides/EXTENSIONS.md#alternatives): Create (nested) alternative routes.
- [Alternative Getters](docs/guides/EXTENSIONS.md#alternative-getters): Get alternatives for the current route.
- [Verified Routes](docs/guides/EXTENSIONS.md#verified-routes): Branch aware variant of Phoenix.VerifiedRoutes.
- [Assigns](docs/guides/EXTENSIONS.md#assigns): Use route attributes as assigns in templates.
- [Interpolation](docs/guides/EXTENSIONS.md#interpolation): Use attributes in route definitions.
- [Translations](docs/guides/EXTENSIONS.md#translations): Translate route segments / full localized URLs.
- [Attribute Getters](docs/guides/EXTENSIONS.md#attribute-getters): Retrieve `Routex.Attrs` for a route.
- [Cldr Adapter](docs/guides/EXTENSIONS.md#cldr-adapter): Use an existing `:ex_cldr`configuration.
- [Plugs](docs/guides/EXTENSIONS.md#plugs): Integrate plugs provided by extensions.
- [LiveView Hooks](docs/guides/EXTENSIONS.md#liveview-hooks): Attach LiveView Lifecycle hooks provided by extensions.
- [Route Helpers](docs/guides/EXTENSIONS.md#route-helpers): Create branch aware Phoenix Helpers.
- [Cloak](docs/guides/EXTENSIONS.md#cloak-showcase): Showcase to demonsrate extreme route transformations.

