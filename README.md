# 
![Logo of Routex](assets/logo_horizontal.png "Routex Logo")

![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)

# Routex: Phoenix route localization and beyond....

Routex is a comprehensive, batteries included framework built on top of Phoenix,
designed to streamline and empower your routing workflows. By simplifying route
manipulation at compile time and enabling the use of custom route attributes
during runtime, Routex provides the granular control needed to tackle the most
complex routing challenges.

Its modern, extensible architecture allows for effortless creation of custom
solutions, extending its functionality far beyond standard routing.

## Localize Phoenix
For developers seeking robust Phoenix localization solutions, Routex excels. It
offers a suite of extensions enabling internationalization (i18n) and
localization (l10n), including but not limited to seamless support for
translated (multilingual) URLs, locale preference detection at run time and
support for multiple backends. Included extension SimpleLocale simplifies common
Phoenix localization by including a [IANA](https://www.iana.org/) based locale
registry for robust locale validation and conversion to display names.

Forget any notion of difficult setup – localizing your Phoenix application with
Routex is a breeze. Just copy the example configuration from our [Localize
Phoenix using Routex guide](docs/guides/LOCALIZE_PHOENIX.md) for an effortless
start.

<p class="hidden-at-hexdocs">
This documentation reflects the main branch. For the latest
stable release, refer to <a href="https://hexdocs.pm/routex/readme.html">HexDocs</a>).
</p>

## Benefits and Features:

* **Simplify development:** Routex combines compile-time code generation with
  dynamic runtime behavior by seamlessly integrating LiveView lifecycle hooks
  and pipeline Plugs. This enables extensions to provide powerful runtime
  features such as automatically locale detection and synchronization between
  the server, client, and LiveView processes- without requiring modifications
  throughout your codebase.

* **Drop-in solution:** Extensions are highly configurable, allowing you to use
  Routex features as drop-in solution. For example: Routex can be configured to
  remain compatible with Phoenix' template generators. As such, it doesn't
  disrupt standard Phoenix development practices lowering the learning curve. It
  can also be configured to mimic Cldr-Routes with its tight integration wirth
  Cldr and use of custom sigils.

* **Optimized Performance:** Positioned between route configuration and
  compilation, Routex core enhances Phoenix routes without incurring additional
  runtime costs. Extensions too are optimized for runtime performance, making
  use of Elixirs superb pattern matching.

* **No dependencies, no state**: Routex is unique in not depending on other
  libraries and works out-of-the-box without proces state. An extension to
  control third-party libraries that do rely on state such as Gettext is
  included.

* **Detailed documentation**: Comprehensive, well-organized documentation
  provides clear guidance on installation, configuration, and best practices,
  making Routex approachable for developers at all levels.


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
- [Attribute Getters](docs/EXTENSIONS.md#attribute-getters): Fetch custom attributes for a route.
- [Alternatives](docs/EXTENSIONS.md#alternatives): Create (nested) alternative routes.
- [Alternative Getters](docs/EXTENSIONS.md#alternative-getters): Get alternatives for the current route.
- [Assigns](docs/EXTENSIONS.md#assigns): Use route attributes as assigns in templates.
- [Cldr Adapter](docs/EXTENSIONS.md#cldr-adapter): Use an existing `:ex_cldr`configuration.
- [Cloak](docs/EXTENSIONS.md#cloak-showcase): Showcase to demonsrate extreme route transformations.
- [Interpolation](docs/EXTENSIONS.md#interpolation): Use attributes in route definitions.
- [LiveView Hooks](docs/EXTENSIONS.md#liveview-hooks): Integrate LiveView Lifecycle hooks provided by other extensions.
- [Plugs](docs/EXTENSIONS.md#plugs): Integrate plugs provided by other extensions.
- [Route Helpers](docs/EXTENSIONS.md#route-helpers): Create branch aware Phoenix Helpers.
- [Runtime Callbacks](docs/EXTENSIONS.md#runtime-callbacks): Call arbitrary functions with route attributes at runtime.
- [Simple Locale](docs/EXTENSIONS.md#simple-locale): Simplifies common Phoenix localization (based on[IANA](https://www.iana.org/) locale registry).
- [Translations](docs/EXTENSIONS.md#translations): Translate route segments / full localized URLs.
- [Verified Routes](docs/EXTENSIONS.md#verified-routes): Branch aware variant of Phoenix.VerifiedRoutes.


## Development
Contributions to Routex are highly appreciated! Whether it's a simple typo fix,
a new extension or any other improvement.

Want to validate your idea? [Use our discussion
board](https://github.com/BartOtten/routex/discussions)

- **clone Routex: https://github.com/BartOtten/routex**  
  The main branch is the active development branch.

- **clone Routex Example app: https://github.com/BartOtten/routex_example**  
  Use either the main branch or watch for branches indicating a newer version

- **copy or symlink `routex` into `routex_example`**  
  This causes the example to use the locale routex

- **enable AST insight in the example app**  
  Inspecting the helpers generated by Routex' extensions helps a lot

  ```elixir
  # In routex_example/config/dev.ex
  config :routex, helper_mod_dir: "/tmp"
  ```

