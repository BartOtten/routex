# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->
## v1.2.0-rc.1

### SimpleLocale has split: Localize.Phoenix.Routes and Localize.Phoenix.Runtime

#### Localize.Phoenix.Routes: Generate localized routes with ease
Localize Phoenix routes using simple configuration.

At compile time, this extension generates localized routes based on locale tags.
These locale tags are automatically derived from your Cldr, Gettext or Fluent
setup and can be overriden using the extensions options.

When using a custom configuration, tags are validated using a build-in locale
registry based on the authoritive IANA Language Subtag Registry.


- `locales`: A list of locale definitions. Defaults to known locales by Cldr,
  Gettext or Fluent (in that order). Each entry can be:
    - A locale string (e.g., `"en"`, `"fr-CA"`).
    - A tuple `{locale, attrs}` to override or add attributes for that specific locale branch.

    **Example:**
    ```elixir
    locales: [
      "en", # Standard English
      {"en-GB", %{currency: "GBP"}}, # UK English with specific currency
      "fr"
    ]
    ```

  ...or synchronize locales with Gettext:

   ```elixir
   locales: Gettext.known_locales(MyAppWeb.Gettext),
   default_locale: Gettext.default_locale(MyAppWeb.Gettext)
   ```

  When not defined, the setup will be derived from Cldr, Gettext of FLuent (in that order) when installed.

- `default_locale`: The locale for top-level routes (e.g., /products). Default
  to the default locale of Cldr, Gettext or Fluent (in that order) with fallback
  to "en".

- `locale_prefix_sources`: List of locale (sub)tags to use for generating
     localize routes. Will use the first (sub)tag which returns a non-nil value.
     When no value is found the locale won't have localized routes.

     Note: The `default_locale` is always top-level / is not prefixed.

     Possible values: `:locale` (pass-through), `:region`, `:language`, `:region_display_name` and `language_display_name`.
     Default to: `[:language, :region, :locale]`.

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

####  Localize.Phoenix.Runtime: Plug and Hook
Plug and play locale detection in StaticViews and LiveViews. Being highly
customizable this locale detection adapts to your project instead of the other
way around.

### Other

- feat: auto detection and usage of existing Cldr, Gettext or Fluent setup.
- feat: support `locales` and `default_locale` for auto generated localized routes
- feat: support attribute overrides for `locale` attributes
- feat: support attribute overrides for `locale` attributes
- docs: improved documentation of Localization guides
- docs: improved documentation of the Localize modules

## v1.2.0-rc.0

This release is truly the result of community participation. Thanks to all
opening tickets and contributing improvements!

### Simplified Integration
Routex now streamlines integration with your Phoenix application by extending
its functionality from compile time to runtime. This means that while route
configurations are established during compilation, Routex now supports dynamic
adjustments at runtime and influencing runtime state.

**Call functions at runtime using (custom) Routex attributes**

  `Routex.Extension.RuntimeCallbakcs` allows you to configure callback functions
   -triggered by the Plug pipeline and LiveViews handle_params- by providing a
   list of `{module, function, arguments}` tuples. Any argument being a list
   starting with `:attrs` is transformed into `get_in(attrs(), rest)`.

  This is particularly useful for integrating with internationalization libraries like:

  * Gettext - Set language for translations
  * Fluent - Set language for translations
  * Cldr - Set locale for the Cldr suite

```elixir
dispatch_targets: [
  # Set Gettext locale from :language attribute
  {Gettext, :put_locale, [[:attrs, :language]]},
]
```

**Inline LiveView Hooks of extensions**

  `Routex.Extension.LiveViewHooks` detects custom hooks provided by other
  extensions and integrates them automatically into Phoenix LiveView’s
  lifecycle. This reduces manual setup and minimizes boilerplate code.

**Inline Plugs of extensions**

  `Routex.Extension.Plugs` detects custom plugs provided by other extensions
  simplifying how extension-specific plugs are incorporated into the router’s
  plug pipeline—just a single `:routex` plug in your router module is enough to
  wire everything together. This approach cuts down on the need for extra
  configuration in your router.

  To utilize the plugs detected by this extension, add the Routex plug to your
  router module in a pipeline.

  ```diff
  # In your router.ex
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
  +  plug :routex
  end
  ```

**Localize your Phoenix app**
`Routex.Extension.SimpleLocale` is included as _tech preview_.

All the aformentioned features are the result of a single issue raised:

> Localization guide is missing step to content translation (using Gettext)
> - KristerV

So a journey began as it was this time we recognized users would like to:

1. use configuration from Routex to influence the runtime behavour of their apps
2. use a simple solution for common localization

SimpleLocale was designed to provide just that: A solution for the most common
cases of localization. Featuring automated integration, a small locales registry
and very customizable locale detection at runtime.

**Compile time** - During compilation this extension expands the `locale`
attribute into `locale`, `language`, `region`, `language_display_name` and
`region_display_name` using the included locale registry (see below).

**Run time** - It provides a Liveview lifecycle hook and a Plug to set the
`locale`, `language` and `region` attributes at runtime from a configurable
source. Each fields source can be independently derived from the accept-language
header, a query parameter, a url parameter, a body parameter, the route or the
session for the current process.

This extensions comes with a simple locale registry covering common needs. The
`language/1` and `region/1` functions can be used to translate locale, region
and language identifiers to display names. `language?` and `region?` validate
input.

```
iex> Routex.Extension.SimpleLocale.Registry.language("nl-BE")
%{descriptions: ["Dutch", "Flemish"], type: :language}

iex> Routex.Extension.SimpleLocale.Registry.region("nl-BE")
%{descriptions: ["Belgium"], type: :region}


iex> Routex.Extension.SimpleLocale.Registry.language("nl")
%{descriptions: ["Dutch", "Flemish"], type: :language}

iex> Routex.Extension.SimpleLocale.Registry.region("BE")
%{descriptions: ["Belgium"], type: :region}
```


Supports languages and regions defined in the [IANA Language Subtag
  Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)

See it's documentation for the available configuration options. Feedback is
highly appreciated.


### Improved Developer Experience

**Clearer Error Messages**

Configuration issues now trigger clearer error messages. Instead of encountering
a full stacktrace, you receive concise guidance to help pinpoint and resolve
common mistakes. Such as:

```
Routex Error: Missing required implementation of `attrs/1`.

       None of the enabled extensions provide an implementation for `attrs/1`.
       Please ensure that you have added and configured an extension that
       implements this function. For more details on how to set up the
       AttrGetters extension, see the documentation:

       https://hexdocs.pm/routex/Routex.Extension.AttrGetters.html
```

```
Extension 'Routex.Extension.404' is missing
```


**Faster Compilation**

Optimizations have been made to improve compile times, even when managing
configurations with a large number of routes. A brief summary of the processed
routes is now provided during compilation.

```elixir
Routex.Processing >> Routes >> Original: 16 | Generated: 100 | Total: 116
```

#### Enhanced Reliability and Debugging

**Increased Test Coverage**

With over 90% test coverage, the core functionality and error-handling paths
have been thoroughly verified. This improvement helps reduce regressions and
ensures better stability.

#### Extension Development


**AST Inspection Option**

A new configuration setting allows developers to output the generated Abstract
Syntax Tree (AST) for inspection. This additional transparency can be valuable
for diagnosing issues during macro-based code generation.

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
end
```


**Provide LiveView Lifecycle Hooks**

`Routex.Extension.LiveViewHooks` detects LiveView Lifecycle callbacks and
inlines their bodies. Each callback receives the standard LiveView parameters
plus `attrs` containing the current route's Routex attributes.

**Available Callbacks**

- `handle_params/4`
- `handle_event/4`
- `handle_info/4`
- `handle_async/4`
- `after_render/4`

**Example**

```elixir
# In a Routex extension
defmodule MyExtension do
  @behaviour Routex.Extension

  # Hook receives the same parameters as LiveView plus attrs
  def handle_params(params, url, socket, attrs) do
    # Modify socket based on Routex attributes
    {:cont, assign(socket, my_key: attrs.my_value)}
  end

  def handle_event(event, params, socket, attrs) do
    # Custom event handling with route context
    {:cont, socket}
  end
end
```


**Provide a Plug**

`Routex.Extension.Plugs` detects `plug/3` callbacks and
inlines their bodies. The callback receives the standard `Plug.call` parameters
plus `attrs` containing the current routes' Routex attributes.

**Example**

```elixir
defmodule MyExtension do
  @behaviour Routex.Extension

  def plug(conn, _opts, attrs) do
    # Access route-specific attributes
    if attrs.require_auth do
      MyAuth.ensure_authenticated(conn)
    else
      conn
    end
  end
end
```

### Bug Fixes:

* core: warnings generated by mix docs
* core: compilation failure due to uncompiled backends



## [v1.1.0](https://github.com/BartOtten/routex/compare/v1.0.0...v1.1.0) (2025-02-13)




### Features:

* provide assigns directly in conn

* core: add function to print critical messages

### Bug Fixes:

* match patterns fail on trailing slash

* undefined on_mount/4, silent missing attrs/1

## [v1.0.0](https://github.com/BartOtten/routex/compare/v0.3.0-alpha.4...v1.0.0) (2025-02-03)




### Features:

* support Phoenix Liveview >= 1.0

### Bug Fixes:

* ci: upgrade artifact actions in workflow

* core: comp. error - cannot set :__struct__ in struct definition

* incorrect typespecs

* cldr: use territory_from_locale for territory resolution


## v0.x

The CHANGELOG for v0.x releases can be found in the [v0.x branch](https://github.com/BartOtten/routex/blob/v0.x/CHANGELOG.md).
