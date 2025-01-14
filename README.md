![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)


# Routex: Supercharge your Phoenix Router

Routex is a powerful, developer-friendly routing library build on top of Phoenix
Router. It is designed to simplify route manipulation —giving developers a new
level of control over route management. Whether it’s multilingual URLs, route
interpolation, or alternative route management, Routex can deliver.

Due to its focus on flexibility, Routex is suited for both small and large-scale
projects, allowing for seamless integration into existing codebases or entirely
new applications. You simply enable the extensions your project needs or write
them yourself without having to worry about the plumbing.

## Top Features and Benefits

* **Dynamic Routing**: Routex supports complex route structures, including
  localized alternatives.
* **Extension driven**: Being extension driven, Routex can be adapted to your
  needs without overhead of unused features. It's architecture allows you to
  write your own features without having to worry about breaking existing
  functionality. Routex ships with extensions covering a wide range of use
  cases. Have a look at [a summary of extensions](EXTENSION_SUMMARIES.md).
* **Optimized for Performance**: Built to fit directly into the Phoenix routing
  system and with a focus on compile time, Routex enhances functionality without
  adding runtime overhead, ensuring that applications run as fast as ever.
* **Detailed Documentation**: Comprehensive, well-organized documentation
  provides clear guidance on installation, configuration, and best practices,
  making Routex approachable for developers at all levels. For example: If you
  are interested in localized routes have a look at the [Localized Routes Tutorial](TUTORIAL_LOCALIZED_ROUTES.md).


## Demo

See Routex in action at the [official Routex Demo page](https://routex.fly.dev/).


## Requirements and Installation

See the [Usage Guide](USAGE.md) for the requirements and installation
instructions.


## Documentation

[HexDocs](https://hexdocs.pm/routex) (stable) and [GitHub
Pages](https://bartotten.github.io/routex) (development).


## Routex vs Cldr Routes vs Phoenix Localized Routes

The capabilities and advancements within `Routex` surpass those of `Phoenix
Localized Routes`, offering a comprehensive array of features. As Phoenix
Localized Routes has stagnated in its development, developers are strongly
advised to transition to Routex for a more robust solution.

When considering `Routex` against `Cldr Routes`, it's akin to comparing Apple to
Linux. Cldr Routes is a limited walled garden but is developed by the main Cldr
developer ensuring maximum compatibility. Routex on the other hand boasts a
wider and more dynamic feature scope providing maximum freedom. Its primary
advantages over Cldr Routes are it's extension mechanism and the minimized
necessity for code modifications throughout a codebase.

But why choose when you can have Cldr through [the Cldr extension for
Routex](`Routex.Extension.Cldr`)?

### Comparison table

| Feature             | Routex     | Cldr Routes | PLR        |
|---------------------|------------|-------------|------------|
| Route encapsulation | Full  [^1] | Limited     | Limited    |
| Route manipulation  | Full  [^2] | Limited     | Limited    |
| Route interpolation | Full       | Limited     | No         |
| Alternative Routes  | Full       | Cldr        | Full       |
| Translation         | ☑          | ☑          |  ☑         |
| Route Helpers       | ☑          | ☑          |  ☑         |
| Verified Routes     | ☑          | ☑          |  ☐         |
| Drop-in replacement | ☑     [^3] | ☐          |  ☑         |
| Standalone          | ☑          | ☐          |  ☐         |
| Modular             | ☑          | ☐          |  ☐         |
| Extendable          | ☑          | ☐          |  ☐         |

[^1]: Routex' `preprocesss_using` is not bound to Phoenix (session) scopes
[^2]: [Crazy example](https://github.com/BartOtten/routex/blob/main/lib/routex/extension/cloak.ex)
[^3]: Routex *can* be configured to shim original Phoenix functionality (for
    example: `~p` and `url/2`) while Cldr Routes mandates code modifications
    (for example: `~p` -> `~q` and `url/2` -> `url_q/2`)
