# Routing Solutions for Phoenix: A Comparison of Key Differences

When working with the Phoenix framework, developers often seek solutions to
address their routing needs. These routing needs range from common requirements
such as internationalization and localization to more specialized needs such as
route obfuscation.

This comparison includes three notable routing solutions within the Phoenix
ecosystem. Each solution has a different scope—ranging from basic to virtually
endless—allowing you to select the one that best aligns with your application's
requirements.

We will delve into several aspects which differ significantly, including
functionality and extensibility, compatibility with existing codebases, runtime
features, and customization options.

By the end of this article, you will have a clear understanding of the strengths
and limitations of each library, enabling you to make an informed decision for
your Phoenix project.


## Phoenix Router, the basic buildin

The Phoenix Router is the built‐in routing system of the Phoenix framework. It
is the base other solutions build upon.

Since version 1.8, it supports runtime path prefixing which automatically
prefixes routes in templates with the result of one or multiple functions. This
feature enables the most basic route localization, known for it's language
prefixes (e.g `/en/products/12/edit` and `/fr/products/12/edit`)


## Comparing Cldr Routes and Routex

 **Cldr Routes** and **Routex** aim to enhance the routing capabilities of
Phoenix, but they differ significantly in their approach and feature set. This
article will focus on their greatest differences to help developers make an
informed decision.


### Functionality and Extensibility


#### Features
**Cldr Routes** focuses on localization enabling users to enter URLs using
localized terms. Additionally, Cldr Routes generates localized path and URL
helpers, making it easier for developers to work with localized routes.

**Routex** is, in terms of features, a superset of Cldr Routes. It not only
matches the internationalization and localization features of Cldr Routes, but
adds support for a wider range of routing needs. It's open-ended design makes
the feature set virtually limitless.

*Both*
- Localized routes
- Translated route segments

*Routex only*
- Custom assigns per route
- Automated Liveview livecycle hooks and Plugs
- Alternative routes
- Reordered route segments
- Route obfuscation
- etc.


#### Architecture

**Cldr Routes** is designed to seamless extend the [Cldr
library](https://github.com/elixir-cldr/cldr). It therefor requires the
integration and configuration of the `Cldr` and `Gettext` libraries. Depending
on your project this might require the addition of the Cldr dependency and
additional setup besides Cldr Routes itself.

The monolitic approach, in contrast to Routex, in combination with being part of
the Cldr-suite ensures a seamless integration and consistent API within the Cldr
ecosystem.

**Routex** is designed as an standalone, extensible framework. As a result
Routex has no hard dependency on other libraries. However, some extensions
may use other libraries such as Gettext or Cldr when enabled.

This modular approach provides developers with the flexibility to incorporate
only the features and dependencies necessary for their specific use case.


#### Customization

**Cldr Routes**' design may establish certain limitations when it comes to
adding new features or modifying existing behavior in Cldr Routes. Due to its
tight integration with the Cldr library new feature or change in behavior will
likely need to align with the overall structure and functionality of Cldr. To
implement a new feature or slightly different behavior downstream, developers
typically need to fork the project.

**Routex**, being a framework, tries to simplify the process of adding new
features or modifying existing behavior.

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

| **Generated code:**  |                              |                                                  |     |
|----------------------|------------------------------|--------------------------------------------------|-----|
| **Helper functions** | Many, provided by extensions | - Link headers - Route helpers - Verified routes | N/A |
| **Conn Plugs**       | Yes                          | No                                               | No  |
| **Liveview Hooks**   | Yes                          | No                                               | No  |



<sub>
Routex can be configured to shim original Phoenix functionality (for example: `~p` and `url/2`) or
mimic Cldr Routes using the [Cldr adapter extension](https://hexdocs.pm/routex/Routex.Extension.Cldr.html).
</sub>


## Conclusion

In summary, each routing solution brings valuable capabilities to the table.

**Phoenix Router** offers a reliable, built-in option for standard routing
needs.

**Cldr Routes** is primarily designed to extend the capabilities of the `Cldr`
library, focusing on localization and internationalization. It provides
compile-time translations for route paths using `Gettext`, enabling users to
navigate applications using localized terms. However, the tight integration with
`Cldr` and `Gettext` libraries imposes certain limitations on customization and
flexibility.

**Routex**, on the other hand, offers a more flexible and extensible
architecture that not only matches the internationalization and localization
features of Cldr Routes but goes beyond. Routex includes all the features
provided by Cldr Routes and adds additional functionalities without the need for
workarounds. Its modular approach allows developers to incorporate only the
components necessary for their specific use case, making it a comprehensive
solution for advanced routing needs.
