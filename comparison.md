# Routing Solutions for Phoenix: A Developer-Centric Comparison

When building applications with the Phoenix framework, you might need additional
routing solutions. Requirements can range from the common internationalization
and localization to more exotic such as route obfuscation. Selecting the right
tool is essential. This article compares two libraries that extend the Phoenix
Router: **Cldr Routes** and **Routex**.

We’ll examine differences in functionality, extensibility, integration, runtime
capabilities, and customization. By the end, you’ll have a clearer picture of
each solution’s strengths and limitations to help you decide which is best for
your project.

## Summary

Both Cldr Routes and Routex extend Phoenix Router in meaningful ways.

**Cldr Routes**  
Cldr Routes provides route translation and generates localized path and URL
helpers. While Cldr Routes streamlines the process of creating localized routes,
it necessitates proper configuration of both Cldr and Gettext. This requirement
is advantageous for projects already utilizing these libraries but may involve
additional setup for others.

Cldr Routes is particularly well-suited for applications that are already part
of the Cldr ecosystem and require straightforward URL translations.

**Routex**  
​Routex is a comprehensive routing framework built on Phoenix Router, offering
extensive internationalization and localization features that encompass all
capabilities of Cldr Routes. Beyond these, Routex introduces a versatile set of
functionalities, including runtime support through built-in Plug and LiveView
lifecycle hooks, as well as customizable function callbacks for navigation
events. ​

A key strength of Routex lies in its seamless integration with existing
codebases, preserving established patterns. Its modular architecture and
extensive customization options enable developers to incorporate custom route
attributes and alternative routing strategies with minimal disruption. This
flexibility ensures that Routex can adapt to the specific needs of any project,
enhancing routing capabilities without necessitating significant codebase
modifications. ​

Routex is recommended for new projects or projects needing to retrofit routing
features into the existing code bases. Its focus on developer experience means
you spend less time configuring and more time building innovative
applications.For projects invested in Cldr it offers `Routex.Extension.Cldr` as
a convenient adapter mimicing Cldr Routes.

## Tabular comparison

A quick overview before diving into a detailed explanation:

| **Feature**             | **Routex**            | **Cldr Routes**            |
| Localized routes        | Yes                   | Yes                        |
| Translated routes       | Yes                   | Yes                        |
| Verified Routes         | Yes                   | Yes                        |
| Route interpolation     | Yes                   | Yes                        |
| Alternatives routes     | Yes                   | Limited                    |
| Custom attributes       | Yes                   | No                         |
| Custom assigns          | Yes                   | No                         |
| Plug & Hooks            | Yes                   | No                         |
| Navigation callbacks    | Yes                   | No                         |
| Buildin locale registry | Yes                   | No                         |
| Route Obfuscation       | Yes                   | No                         |
|                         |                       |                            |
| **Integration**         | **Routex**            | **Cldr Routes**            |
| Sigils                  | Customizable          | Fixed                      |
| Functions               | Customizable          | Fixed                      |
| Libs integration        | Configurable          | None                       |
| Dependencies            | Configurable          | Cldr, Gettext              |
| Runtime integration     | Automated             | None                       |
|                         |                       |                            |
| **Development**         | **Routex**            | **Cldr Routes**            |
| Architecture            | Modular               | Monolithic                 |
| Feature inclusion       | Upstream or extension | Upstream or own fork       |
| Internal format         | Route structs         | Abstract Syntax Tree (AST) |
| Tooling included        | Yes                   | No                         |


## Feature Set & Extensibility

Both libraries were inspired by PhxAltRoutes—a pioneering localized
routing effort by Routex’s creator—but have since taken distinct evolutionary
paths.

**Cldr Routes**  
Reduced the feature set to localization features only. Aligning with the goals
of Cldr.

- **Localization:** Translates URL path segments at compile time and generates
  localized helper functions.
- **Fixed Integration:** Relies on the Cldr and Gettext libraries for
  localization.

**Routex**  
Designed to be modular; allowing to grow the feature set beyond localization
without becoming a large monolithic lib and supporting extension orchestration through
value passing.

- **Comprehensive Feature Set:** Beyond matching the internationalization and
  localization capabilities of Cldr Routes, Routex also offers advanced features
  like custom assigns, alternative route generation, and support for route
  segment reordering —providing unmatched flexibility
- **Integrated Extensions:** Built-in support for Plugs and LiveView lifecycle
  hooks automates integrations and speeds up development.
- **Integrated locale registry:** Routex comes with a simplified -IANA subtag
  registry based- locale registry . It covers common localisation use cases such as
  translating locale, region and language identifiers to display names and
  validating locale tags.
- **Modular Architecture:** Its extension-driven architecture allows you to
  include only the features you need and easily create custom extensions.
- **Focus on Customization:** The mantra "Simple by default, powerful when
  needed" drives the development of extensions. Extensions ship with sane
  defaults yet are highly tweakable due to a sheer amount of configuration
  options.
- **Tailor-Made Customization:** Its modular architecture and the information
  sharing system `Routex.Attrs` lets you extend functionality without having to
  worry about the core of routing or breaking other extensions. Clone an
  extension, tweak it to your needs, or build new ones from scratch.

Below is a feature comparison summarizing key differences:

### Localized Routes
While both libraries feature localized routes, Routex offers customization
options such a customized locale notation and display name overrides for
languages and regions.

### Translated Routes
While both libraries feature translate routes by depending on Gettext, Routex
only depends on Gettext when the Translations extension is enabled.

### Route Manipulation
Both libraries feature route manipulation in different degrees. Transformations
by Cldr Routes are limited to localization. Routex, in contrast, allows for any
kind of transformation including custom attributes, non-locale alternative
routes, and route segment reordering.

### Plug & LiveView Integration
Only Routex provides native support for Plug and LiveView extensions

### Dependencies
Cldr Routes requires Cldr and Gettext. Although Routex core has no dependencies
on itself extensions may require additional dependencies. At this moment only
the Translations extension has a dependency: Gettext.

### Integration with other packages
Unlike Cldr Routes, Routex is designed to seamlessly integrate with any
third-party package you choose. This flexibility allows you to combine Routex
with your existing package stack or custom solutions, tailoring its
functionality to meet the specific needs of your application.

## Developer Experience & Integration

**Cldr Routes**  
Streamlines localized route generation. However, its tight integration with the
Cldr suite and limited configuration options can limit flexibility and often
necessitates adjustments in templates and code. Requiring the use of a custom
sigil `~q` for verified routers and `q` prefixed helper macros, it necessitates
adjustments in existing templates and newly generated ones. The impact depends
on the size of the code base and the use of generators.

```heex
# Example in Cldr Routes:

# Uses custom sigil ~q for localized routes
<.link navigate=~q"/products/#{product}">My Link</.link>
```


**Routex**  
In contrast, Routex offers extensive configurability -such as customizable
sigils and function names. It can be configured to shim the default Phoenix
sigil `~p` and helper macros `url` and `path` or mimic Cldr Routes for Cldr
integration by using it's custom sigil and macros names. Meaning you can
seamlessly incorporate Routex into your existing projects, preserving familiar
patterns while enjoying cutting-edge features. Support for extensions with
runtime features reduce manual wiring.

```heex
# Example in Routex:

# Configurable to use standard Phoenix sigil ~p (as used in Phoenix' generators)
<.link navigate=~p"/products/#{product}">My Link</.link>

# or mimic Cldr Routes using sigil ~q
<.link navigate=~q"/products/#{product}">My Link</.link>
```

This flexibility is particularly useful when integrating with existing projects
and code bases.

## Route processing

Both projects generate routes during compile time. It's the way how they
do this and their runtime capabilities that makes the difference.

**Cldr Routes**  
Cldr Routes takes your original route definition Abstract Syntaxt Tree (AST)
within a localize block and transforms it into a new AST with localized paths.
There are no points for interception or extension points in this proces.

```elixir
 localize do
    get "/pages/:page", PageController, :show
    resources "/users", UserController
  end
```


**Routex**  
Routex intercepts your route definitions after they have been converted into
straightforward Route structs. It's extension processing system uses "value
passing" so each extension in the pipeline receives the route structs including
attributes and can modify or augment them before passing the updated routes on
to the next extension. This approach makes it easier to trace and debug route
transformations at compile time.

At the end of the processing Routex passes the route structs to Phoenix Router
for native compilation.

This approach leverages the simpler and more predictable structure of Route
structs and route compilation by Phoenix Router itself, making the system more
flexible, simpler to extend and easier to understand.

```elixir
# Routex supports the use of multiple configuration backends in one router. This means
# that routes can have their own transformations, helper functions, or runtime features.

# using configuration ExampleWeb.RoutexBackend
preprocess_using ExampleWeb.RoutexBackend do
   get "/pages/:page", PageController, :show
   resources "/users", UserController
end

# using ExampleWeb.RoutexBackendAdmin
preprocess_using ExampleWeb.RoutexBackendAdmin do
   get "/admin/:page", PageController, :show
end
```



## Runtime capabilities

**Cldr Routes**
Cldr Routes features only branching verified routes during runtime. It relies on
external dependencies (like Cldr Plugs) to manage runtime locale detection,
which necessitates adjustments in configuration and code for runtime
localization.


**Routex** Routex offers virtually unlimited runtime features and integration by
integrating native extension `Routex.Extension.RuntimeDispatcher` for dynamic
functionality. This can be combined with other extensions -such as
`Routex.Extension.Localize.Phoenix.Runtime` for highly customizable locale
detection and behavior during runtime.

```elixir
defmodule ExampleWeb.RoutexBackend do
use Routex.Backend,  # makes this a Routex configuration backend
extensions: [
  Routex.Extension.Attrs,
     Routex.Extension.Localize,  # detects locale, and puts it in runtime attributes
     Routex.Extension.RuntimeDispatcher  # call arbitrary functions during runtime using route attributes
],
# configuration of arbitrary functions to be called at navigation events.
dispatch_targets: [
 # Set Gettext locale from :language attribute
 {Gettext, :put_locale, [[:attrs, :language]]},
 # Call arbitrary function using other runtime attribute
 {MyApp, :my_function, ["my value", [:attrs, :runtime_attr_value], "other value"]}
]
end
```


Routex supports extension-provided plugs and hooks that are generated at compile
time. By leveraging Elixir's powerful pattern matching, these plugs and hooks
are optimized for performance, ensuring minimal runtime overhead even when
multiple runtime dispatch targets are enabled.​

## Conclusion

In summary, both Cldr Routes and Routex significantly enhance Phoenix’s routing
capabilities, but they cater to different project needs. Cldr Routes offers a
streamlined, localized routing solution ideal for applications already using the
Cldr and Gettext ecosystems.

On the other hand, Routex stands out with its modular and extensible
architecture. It not only replicates the localization features of Cldr Routes
but also introduces advanced functionalities—such as customizable route
attributes, runtime dispatching to external libs, and seamless integration with
Plug and LiveView. This flexibility makes Routex a powerful choice for both new
projects and those looking to integrate dynamic routing features into an
existing codebase.

Ultimately, the decision between these libraries will depend on your project’s
requirements, existing dependencies, and desired level of customization. For
developers seeking a robust and adaptive routing framework, Routex offers
extensive configurability and a richer feature set, while Cldr Routes remains a
compelling choice for straightforward localization needs.

---

<small>
The `routex` -formerly known as `route_match`- as used by HandleCommerce
is not related to the Routex as decribed in this document.
</small>
