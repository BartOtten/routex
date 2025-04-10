# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->
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
runtime_callbacks: [
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
