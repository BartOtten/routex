# Usage

## Requirements

- Elixir >=1.11
- Phoenix >= 1.6.0
- Phoenix LiveView >= 0.16 (optional)


## Installation

You can install this library by adding it to your list of dependencies in `mix.exs`. (use `mix hex.info routex` to find the latest version):

```diff
def deps do
  [
     ...other deps
+    {:routex, "~> 1.0"}
  ]
end
```

Modify the entrypoint of your web interface definition.
```diff
# file: lib/example_web.ex

# in router
+  use Routex.Router  # always before Phoenix Router
   use Phoenix.Router, helpers: false

# in controller
   unquote(verified_routes())
+  unquote(routex_helpers())

# in live_view
      unquote(html_helpers())
+     on_mount(unquote(__MODULE__).Router.RoutexHelpers)

# in view_helpers or html_helpers
   unquote(verified_routes())
+  unquote(routex_helpers())

# insert new private function
+  defp routex_helpers do
+    quote do
+      import Phoenix.VerifiedRoutes,
+        except: [sigil_p: 2, url: 1, url: 2, url: 3, path: 2, path: 3]
+
+      import unquote(__MODULE__).Router.RoutexHelpers, only: :macros
+      alias unquote(__MODULE__).Router.RoutexHelpers, as: Routes
+    end
+  end
```

## Configuration

To use `Routex`, a module that calls `use Routex.Backend` (referred to below as a
"backend") has to be defined. It includes a list with extensions and
configuration of extensions.

Each extension provides a single feature. The extensions have their own
documentation which specifies how to configure and use them. For a short
description and links to documentation per extension, refer to [EXTENSIONS.md].

Too speed up setup all extensions are included in the configuration below
and extensions are configured to act as drop-in replacements.

Note that you might have to rename some `~p` sigils in templates to `~o` to
have these routes _not_ be branch aware.

```elixir
# file /lib/example_web/routex_backend.ex

defmodule ExampleWeb.RoutexBackend do
 alias ExampleWeb.RoutexBackend.AltAttrs

defmodule ExampleWeb.RoutexBackend do
 use Routex.Backend,
   extensions: [
     # required
     Routex.Extension.AttrGetters,

     # adviced
     Routex.Extension.LiveViewHooks,
     Routex.Extension.Plugs,
     Routex.Extension.VerifiedRoutes,
     Routex.Extension.Alternatives,
     Routex.Extension.AlternativeGetters,
     Routex.Extension.Assigns,
     Routex.Extension.Localize.Phoenix.Routes,
     Routex.Extension.Localize.Phoenix.Runtime,
     Routex.Extension.RuntimeDispatcher,

     # optional
     # Routex.Extension.Translations,  # when you want translated routes
     # Routex.Extension.Interpolation, # when path prefixes don't cut it
     # Routex.Extension.RouteHelpers,  # when verified routes can't be used
     # Routex.Extension.Cldr,          # when coming from the Cldr ecosystem
   ],
   assigns: %{namespace: :rtx, attrs: [:locale, :language, :region]},
   verified_sigil_routex: "~p",
   verified_url_routex: :url,
   verified_path_routex: :path
end
```

## Preprocess routes with Routex

`Routex` will preprocess any route wrapped -either direct or indirect- in a
`preprocess_using` block. It uses the backend passed as the first argument. This
allows the use of multiple backends (e.g. to use different extensions for admin
routes)

```diff
# file: router.ex
  pipeline :browser do
      [..]
      plug :put_secure_browser_headers
      plug :fetch_current_user
+     plug :routex
  end

+ preprocess_using ExampleWeb.RoutexBackend do
    scope "/", ExampleWeb do
      pipe_through [:browser, :redirect_if_user_is_authenticated]
      # [...routes...]
    end

    scope "/", ExampleWeb do
      pipe_through [:browser, :require_authenticated_user]
      # [...routes...]
    end
+ end
```

When you run into issues, please have a look at the [Troubleshooting](docs/TROUBLESHOOTING.md)
