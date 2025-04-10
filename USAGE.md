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
and extensions are configured to act as drop-in replacements. Copy this
configuration and make modifications. Notably:

- the Gettext backend module to use
- the alternatives configuration

Also note that you might have to rename some `~p` sigils in templates to `~o` to
have these routes _not_ be branch aware.

```elixir
# file /lib/example_web/routex_backend.ex
# This example uses a `Struct` for custom attributes, so there is no attribute inheritance;
# only struct defaults. When using maps, nested branches will inherit attributes from their parent.

defmodule ExampleWeb.RoutexBackend.AltAttrs do
 @moduledoc false
 defstruct [locale: "en-001"]
end

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
     Routex.Extension.RuntimeCallbacks,
     Routex.Extension.VerifiedRoutes,
     Routex.Extension.AlternativeGetters,
     Routex.Extension.Alternatives,
     Routex.Extension.Assigns,
     Routex.Extension.Localize

     # optional
     # Routex.Extension.Translations,  # when you want translated routes
     # Routex.Extension.Interpolation,  # when path prefixes don't cut it
     # Routex.Extension.RouteHelpers,  # when verified routes can't be used
     # Routex.Extension.Cldr,  # when using Cldr
   ],
   alternatives: %{
    "/" => %{
      attrs: %AltAttrs{contact: "sales@example.com"},
      branches: %{
        "/europe" => %{
          attrs: %AltAttrs{locale: "en-150", contact: "sales.europe@example.com"},
          branches: %{
            "/nl" => %{attrs: %AltAttrs{locale: "nl-NL", contact: "verkoop@example.nl"}},
            "/fr" => %{attrs: %AltAttrs{locale: "fr-FR", contact: "commerce@example.fr"}}
          }
        },
      "/gb" => %{attrs: %AltAttrs{locale: "en-GB", contact: "sales@example.com"}
     },
   },
   alternatives_prefix: true,
   assigns: %{namespace: :rtx, attrs: [:locale, :contact]},
   # translations_backend: MyApp.Gettext,
   translations_domain: "routes",
   runtime_callbacks: [{Gettext, :put_locale, [[:attrs, :language]]}],
   verified_sigil_routex: "~p",
   verified_sigil_phoenix: "~o",
   verified_url_routex: :url,
   verified_url_phoenix: :url_native,
   verified_path_routex: :path,
   verified_path_phoenix: :path_native
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

  scope "/", ExampleWeb, host: "admin.", as: :admin do
    pipe_through :browser

+    preprocess_using ExampleWeb.RoutexBackendAdmin do
      # [...routes...]
+    end
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
