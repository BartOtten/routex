# Announcing Routex 1.2.0 – Effortless Phoenix Localization

I’m thrilled to announce **Routex 1.2.0**, a major update that brings
zero‑config internationalization (i18n) and and localization (l10n) to your
Phoenix apps. It plugs straight into Cldr, Gettext, or Fluent and eliminates the
boilerplate of manual locale plugs and translation hooks.

** Summary **
- Simplified localization
- Comprehensive runtime integration
- Enhanced developer tools
- Community-driven improvements

## 1. Zero-Config Localization with Multilingual Routing

Building multilingual Phoenix sites used to mean scattering locale detection,
LiveView hooks, and dynamic-route logic throughout your code. **Routex 1.2.0**
replaces all that with a single, centralized configuration. Your router stays
clean, localization is applied at compile time, and runtime dispatching
seamlessly handles any additional needs—no extra wiring required.

The new Localization system is a game-changer automatically detecting your
existing Phoenix localization setup and making everything work out of the box.
Let's see this magic in action with a typical Phoenix application:

```elixir
# lib/my_app_web/routex_backend.ex
defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
      extensions: [
        Routex.Extension.Attrs,
        Routex.Extension.LiveViewHooks,
        Routex.Extension.Plugs,
        Routex.Extension.Localize.Phoenix.Routes,
        Routex.Extension.Localize.Phoenix.Runtime,
        Routex.Extension.RuntimeDispatcher
      ]
```

Using the sane defaults of the extensions Routex will transforms your routes
based on your Gettext locales (or Cldr, or Fluent). For example, if your Gettext has "en" (default),
"fr", and "nl" configured, Routex automatically generates:

```elixir
# Example: Generated Routes
# Original route: /products
"/products"          # Default locale (en)
"/fr/products"       # French
"/nl/products"       # Dutch
```

The magic continues at runtime. Routex automatically:
1. Detects the user's preferred language from a variary of sources
2. Sets up Gettext with the correct locale
3. Maintains the locale across LiveView navigation
4. Provides helper functions for switching locales

Want to customize? No problem! The zero-config setup can be enhanced with
explicit configuration. Here are a few examples:

```elixir
# lib/my_app_web/routex_backend.ex

# Override auto-detected locale settings for route generation
locales: ["en-US", "fr-FR", "nl-BE": %{language_display_name: "DUTCH"}}],
default_locale: "en-US",

# Customize URL generation: results in /english, /french, /dutch
locale_prefix_sources: [:language_display_name],

# Customize region detection order: fixed to route attribute, no overrides
region_sources: [:route],

# Customize language detection order
language_sources: [:query, :session, :accept_language, :route]
```

The Localize extensions come with a IANA Language Subtags based locale registry
covering common needs. The `language/1` and `region/1` functions can be used to
translate locale, region and language identifiers to display names. `language?`
and `region?` validate input.

```elixir
# single subtag
iex> Routex.Extension.Localize.Registry.region("BE")
%{descriptions: ["Belgium"], type: :region}

# double subtag
iex> Routex.Extension.Localize.Registry.language("nl-BE")
%{descriptions: ["Dutch", "Flemish"], type: :language}
```


## 2. Enhanced integration with other libraries

For scenarios requiring integration with other third-party libs, Routex 1.2.0
introduces runtime dispatch targets through the
`Routex.Extension.RuntimeDispatcher` extension. The dispatch targets are
automatically called using a Plug and Liveviews events using a LiveView
Lifecycle Hook.

```elixir
dispatch_targets: [
    # Set Gettext locale using detected :language attribute (this is a default)
    {Gettext, :put_locale, [[:attrs, :runtime, :language]]},

    # Custom dispatch using routes :region attribute
    {MyModule, :set_region, [[:attrs, :route, :region]]},
]
```

## 3. Automated LiveView lifecycle hooks and plugs

Two new extensions add support for the detection and auto-enabling of Plugs and
LiveView Livecycle Hooks provided by other extensions. This seamless integration
improves the overall developer experience (DX) by reducing the friction of
additional plug and hook configuration.


```elixir
# lib/my_app_web/routex_backend.ex
extensions: [
  Routex.Extension.LiveViewHooks, #  detects and enables LiveView Lifecycle callbacks
  Routex.Extension.Plugs,         #  detects and enables Plug calls
]
```


## 4. A Better Development Experience

We've completely overhauled the development experience.

- Crystal-clear error messages
- Built-in AST inspection for debugging


#### Clearer Error Messages

Configuration issues now trigger clearer error messages. Instead of encountering
a full stacktrace, you receive concise guidance to help pinpoint and resolve
common mistakes. Such as:


Raised during pre-processing when an extension is missing:

```
Extension 'Routex.Extension.404' not found.
```

Or when the `attrs/1` helper function is missing:

```
Routex Error: Missing required implementation of `attrs/1`.

       None of the enabled extensions provide an implementation for `attrs/1`.
       Please ensure that you have added and configured an extension that
       implements this function. For more details on how to set up the
       AttrGetters extension, see the documentation:

       https://hexdocs.pm/routex/Routex.Extension.AttrGetters.html
```


#### AST Inspection Option

A new configuration setting allows developers to output the generated code for
inspection. This additional transparency can be valuable for diagnosing issues
with the extension-generated helper functions.

```elixir
# In config/dev.ex
config :routex, helper_mod_dir: "/tmp"
```

During compilation, the generated code is saved to your specified directory for review:

```bash
Wrote AST of Elixir.ExampleWeb.Router.RoutexHelpers to /tmp/ExampleWeb.Router.RoutexHelpers.ex
```

Ready to be inspected.
`cat /tmp/ExampleWeb.Router.RoutexHelpers.ex`

```elixir
defmodule ExampleWeb.Router.RoutexHelpers do
  @moduledoc "This code is generated by Routex and is for inspection purpose only\n"

    require Logger
    use Routex.HelperFallbacks

    @doc "Returns Routex attributes of given URL\n"
    def attrs(url) when is_binary(url) do
        url |> Matchable.new() |> attrs()
    end

    # ... all other helper functions ...
```

## 5. Improved Reliability and Performance

### Faster compilation, faster runtime
Several improvements have been made to the Routex pre-processing engine for
better compilation. The revamped processing model brings compile‑time
optimizations, and increases the amount of supported routes to multiple
hundreds.

Build-in extensions have been recrafted for reduced generated code and enhanced
performance thanks to Elixir’s robust pattern matching and function call
optimizations -ensuring that your app remain both fast and reliable.

A brief summary of the processed routes is now provided during compilation.

```elixir
Routex.Processing >> Routes >> Original: 16 | Generated: 100 | Total: 116
```

### Improved Reliability

#### Increased Test Coverage

With over 90% test coverage, the core functionality and error-handling paths
have been thoroughly verified. This improvement helps reduce regressions and
ensures better stability.


## Community Contributions

Welcome to new contributors who have improved the project.

Krister Viirsaar **reported issues** with setup en especially with the Localize
Phoenix tutorial. The issue is titled "Localization guide is missing step to
content translation (using Gettext)". Let's say this lengthy release note is
Routex' reply....thanks Krister!

Niels Ganser and Max Gorin for contributing **fixes to the documentation**. Although
small in size, such contributions make impact. Nobody likes broken links or
incorrect instructions.

A special thanks to Kenneth Kostrešević -you may recognize his name from the Ash
weekly- as he **spotted and fixed an embarrasing regression** before it was released. His
extra addition to the test suite ensures the issue won't sneak into the codebase
again again.

Contributions are highly welcome!

## Looking Forward

As we continue to evolve Routex, our focus remains steadfast on making Phoenix
route management as effortless as possible. This release marks a significant
step toward that goal, with features that not only make development easier but
also more enjoyable.

The next grand release will be focussing on even easier setup. Kenneth Kostrešević
has already begon the work to craft a one-command setup using an **Igniter installer**


## Conclusion

Routex 1.2.0 sets a new benchmark for Phoenix localization by turning a once
cumbersome process into a streamlined, configuration‑driven experience. Upgrade
today to harness automated locale detection, dynamic routing enhancements, and
an unparalleled developer experience that empowers you to build world‑class
multilingual Phoenix applications—all while reducing boilerplate and enhancing
maintainability.

Ready to upgrade? Check out our
[documentation](https://bartotten.github.io/routex/readme.html) for a smooth
transition to the latest version.

Happy coding, and enjoy the future of Phoenix localization with Routex 1.2.0!


---
## TLDR not your cup of tea? The Localize Suite in more Detail

As Routex demands "Simple by default, powerful when needed", it broads not one,
but two extensions for localization.

### 1. Localize.Phoenix.Routes
Localize Phoenix routes using simple configuration.

  At compile time, this extension generates localized routes based on locale
  tags. These locale tags are automatically derived from your Cldr, Gettext or
  Fluent setup and can be overriden using the extensions options.

  #### Notable features
  - **Buildin locale registry**: Locale subtags can be validated and converted to human-friendly display
  names using the buildin locale registry based on the authoritive
  [IANA Language Subtag Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry).
  - **Automated locale expansion**: At _compile time_ this extension will expand a routes `:locale` attribute into multiple attributes such as 
  `:language` (e.g., "en") and `:language_display_name`
  - **Locale branch attributes (overrides)**
    Assign or override attributes for a specific locale routes branch.
     **Example:**
     ```elixir
      locales: [
       # Standard English
       "en",
       # Standard French
       "fr"
       # Language: "English", Region: "Global" displayed as "Worldwide"
       "en-001": %{region_display_name: "Worldwide"},
       # Language: "English", Region: "Great Brittain", Compile time route attributes: %{currency: "GBP"}
       "en-GB": %{currency: "GBP"},
     ]
     ```

     > #### Attribute Merging Precedence (Compile Time, low to high):
     > 1. Derived from locale string
     > 2. Explicit Locale Override (from attrs in tuple)
     > 3. Original Branch Attribute (already existing on the branch)
     >
     > Point 3 ensures this extension plays well with
     > pre-configured alternative branches.

    - **Custom route prefixes**
     Locale attributes to prefix routes with, supporting the automated expanded locale attributes.

     **Examples:**
      ```elixir
      # in configuration
      locales: ["en-001", "fr", "nl-NL", "nl-BE"]
      default_locale: "en"

      # single source
      locale_prefix_sources: :locale =>     ["/", "/en-001", "/fr", "/nl/nl", "/nl-be"],
      locale_prefix_sources: :language => ["/", "/fr", "/nl"],
      locale_prefix_sources: :region =>     ["/", "/001", "/nl", "/be"]
      locale_prefix_sources: :language_display_name =>     ["/", "/english", "/french", "/dutch"]
      locale_prefix_sources: :region_display_name =>     ["/", "/world", "/france", "/netherlands", "/belgium"]

      # with fallback
      locale_prefix_sources: [:language, :region] => ["/", "/fr", "/nl"]
      locale_prefix_sources: [:region, :language] => ["/", "/001", "/fr", "/nl", "/be"]

      ```

### 2. **Localize.Phoenix.Runtime: Advanced Locale Detection**

Routex 1.2.0 automatically detects the user’s locale from multiple independent
sources:

  - Pre-compiled route attributes
  - The `Accept-Language` header sent by the client (`fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7`)
  - Query parameters (`?lang=fr`)
  - Hostname (`fr.example.com`)
  - Path parameters (`/fr/products`)
  - Assigns (`assign(socket, [locale: "fr"])`)
  - Body parameters
  - Stored cookie
  - Session data

The extension comes with sane default, but each parameter can be customized to
make locale detection fit your project instead of the other way around. A uniq
multi‑attribute, multi-source approach empowers your application to adapt the
runtime `language` and `region` using different strategies. This aligns with our
[Localization vs Translation advice](/docs/guides/LOCALIZATION_VS_TRANSLATION.md)

**Example**

```elixir
# In your Routex backend module; all optional
locale_sources: [:query, :session, :accept_language], # Order matters
locale_params: ["locale"], # Look for ?locale=... etc

language_sources: [:path, :host],
language_params: ["lang"], # Look for /:lang/... etc

region_sources: [:route] # Only use region from precompiled route attributes
# region_params defaults to ["region"]
```


By automating locale detection, Routex helps you eliminate error‑prone manual
setup and significantly reduces development time.


