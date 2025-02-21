# Phoenix Framework routing solutions compared

When working with the Phoenix framework, developers often seek routing libraries
that offer robust internationalization and localization features.

This guide outlines three notable routing solutions within the Phoenix
ecosystem. Each solution offers its own strengths and unique features, allowing
you to select the one that best aligns with your application's requirements.

---

## Phoenix Router

The Phoenix Router is the built‐in routing system of the Phoenix framework.
Since version 1.8, it supports simple path prefixing which can be used to
create basic localized routes such as `/en/products` and `/fr/products`.

---

## Comparing Cldr Routes and Routex

Two prominent libraries in this space are **Cldr Routes** and **Routex**. Both
libraries aim to enhance the routing capabilities of Phoenix, but they differ
significantly in their approach and feature set. We will compare Cldr Routes and
Routex, focusing on their greatest differences to help developers make an
informed decision.


### Functionality and Extensibility


#### Features
**Cldr Routes** focuses on localization enabling users to enter URLs using
localized terms. Additionally, Cldr Routes generates localized path and URL
helpers, making it easier for developers to work with localized routes.

**Routex** not only matches the internationalization and localization features
of Cldr Routes, but also supports a wider range of routing requirements. It's
open-ended design makes the featureset virtually limitless as demonstrated by
this [demonstration
extension](https://hexdocs.pm/routex/Routex.Extension.Cloak.html)


#### Architecture

**Cldr Routes** is designed to seamless extend the [Cldr
library](https://github.com/elixir-cldr/cldr). It therefor requires the
integration and configuration of the `Cldr` and `Gettext` libraries. Depending
on your project this might require additional setup besides Cldr Routes itself.

The monolitic approach, in contrast to Routex, in combination with it's
maintenance of the author of Cldr ensures the seamless integration with the Cldr
ecosystem.

**Routex**, on the other hand, is designed as an standalone, extensible
framework. As a result Routex has no hard dependency on other libraries.
However, enabled extensions may used other libraries (such as Gettext for
translations, or Cldr for the Cldr adapter).

This modular approach provides developers with the flexibility to incorporate
only the components and dependencies necessary for their specific use case.


#### Customization

**Cldr Routes**' design may establish certain limitations when it comes to
adding new features or modifying existing behavior in Cldr Routes. Due to its
tight integration with the Cldr library new feature or change in behavior will
likely need to align with the overall structure and functionality of Cldr. To
implement a new feature or slightly different behavior downstream, developers
typically need to fork the project.

**Routex**, in contrast, tries to simplify the process of adding new features or
modifying existing behavior.

Developers can create custom extensions that integrate seamlessly with the core
library and other extensions. If only a slight modification to an existing
Routex extension is needed, developers can clone the relevant extension into
their project and adapt it accordingly. Developers van leverage utilities and
abstractions provided by Routex to simplify the process.

This approach ensures that developers can tailor Routex's functionality to their
unique requirements without deep understanding of it's codebase.


### Compatibility with Existing Codebases

**Cldr Routes** requires the use of the `~q` sigil and `url_q` functions in
place of the standard URL functions for its version of Verified Routes.
Consequently, when utilizing Phoenix generators, developers must modify the
routes in their templates accordingly. The same goes for existing templates,
which may require adjustments to integrate Cldr Routes.

**Routex**, in contrast, allows users to select their preferred sigil and
function names, enabling configuration that maintains compatibility with
generated templates and existing codebases. This flexibility ensures that Routex
can be seamlessly integrated into existing projects without the need for
extensive modifications.


### Runtime Features

**Cldr Routes** requires an additional dependency and configuration to manage
locale settings, such as the excellent [Cldr Plugs](https://github.com/elixir-cldr/cldr_plugs)

**Routex** extensions can include callbacks for Plug and LiveView lifecycle
hooks to, for example, manage locale settings by invoking `Gettext.put_locale`
or `Cldr.put_locale`. These callbacks are automatically enabled upon adding the
extension without modifications to the codebase. This design choice streamlines
the integration process, reducing the need for extra dependencies and
codebase modifications.


## Comparison Table

| Feature                 | Routex                       | Cldr Routes                                              | Phoenix Router |
|-------------------------|------------------------------|----------------------------------------------------------|----------------|
| **Localized routes**    | Yes                          | Yes                                                      | Basic          |
| **Translated routes**   | Yes                          | Yes                                                      | No             |
| **Route modifications** | Yes                          | No                                                       | No             |
| **Drop-in Replacement** | Yes                          | No                                                       | N/A            |
| **Extensible**          | Yes                          | No                                                       | Basic          |
| **Route Manipulation**  | Limitless                    | Tailored for localization needs                          | Basic          |
| **Dependencies**        | None                         | Cldr, Gettext                                            | None           |
| **Code modifications**  | Minimal                      | Neutral                                                  | Nihil          |
|                         |                              |                                                          |                |
| **Generated code:**     |                              |                                                          |                |
| **Helper functions**    | Many, provided by extensions | - Link headers - Route helpers - Verified routes | N/A            |
| **Conn Plugs**          | Yes                          | No                                                       | No             |
| **Liveview Hooks**      | Yes                          | No                                                       | No             |

In summary, each routing solution brings valuable capabilities to the table. Phoenix Router offers a reliable, built-in option for standard routing needs. Cldr Routes provides a specialized approach for multilingual URL management within the Cldr ecosystem. Meanwhile, Routex stands out with its advanced, customizable, and extension-driven approach—making it a versatile choice for those who require more than the basics.

<sub>
Routex can be configured to shim original Phoenix functionality (for example: `~p` and `url/2`) or
mimic Cldr Routes using the [Cldr adapter extension](https://hexdocs.pm/routex/Routex.Extension.Cldr.html).
</sub>
