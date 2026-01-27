# Usage

## Requirements

- Elixir >=1.11
- Phoenix >= 1.6.0
- Phoenix LiveView >= 0.16 (optional)


## Adding Routex to your project
You can install this library by adding it to your list of dependencies in
`mix.exs`. (use `mix hex.info routex` to find the latest version):

```diff
def deps do
  [
     ...other deps
+    {:routex, "~> 1.0"}
  ]
end
```

Next run:
```bash
mix deps.get
```

## Quick config using Igniter

Routex includes an [Igniter](https://hexdocs.pm/igniter/readme.html) install
task that automates the setup process, eliminating the need for manual file
editing.

You can install Igniter adding it to your list of dependencies in
`mix.exs`. (use `mix hex.info igniter` to find the latest version):

```diff
def deps do
  [
     ...other deps
     {:routex, "~> 1.0"},
+    {:igniter, "~> 0.6"}
  ]
end
```

Even though Igniter handles the installation automatically, it's recommended to
review the rest of this page to understand how Routex works and how you can
customize it to fit your specific needs.

```bash
mix deps.get
mix routex.install
```

## Manual config

Modify the entrypoint of your web interface definition.
```diff
# file: lib/example_web.ex

# in router
+  use Routex.Router  # always before Phoenix Router
   use Phoenix.Router, helpers: false

# in controller
   unquote(verified_routes())
+  unquote(routex_helpers())

q
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

Too speed up setup all extensions are included in the configuration below.

```elixir
# file /lib/example_web/routex_backend.ex

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
     Routex.Extension.RuntimeDispatcher

     # optional
     # Routex.Extension.Translations,  # when you want translated routes
     # Routex.Extension.Interpolation, # when path prefixes don't cut it
     # Routex.Extension.RouteHelpers,  # when verified routes can't be used
     # Routex.Extension.Cldr,          # when combined with the Cldr ecosystem
   ],
   assigns: %{namespace: :rtx, attrs: [:locale, :language, :region]},
   verified_sigil_routex: "~p",
   verified_url_routex: :url,
   verified_path_routex: :path,
   dispatch_targets: [
     {Gettext, :put_locale, [[:attrs, :runtime, :language]]}
     # {Routex.Utils, :process_put_branch, [[:attrs, :__branch__]]}
   ]
end
```


## Preprocess routes with Routex

`Routex` will preprocess any route found inside a `preprocess_using` block,
either directly or nested in other blocks such as `scope`.

`preprocess_using` receives the backend module name as the first argument. This
allows the use of distinct backends per `preprocess_using` block (e.g. to use
different extensions for admin routes)

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


## Configuring individual extensions

In the configuration above, a number of extensions are enabled with sensible
defaults to help you get started quickly. Don’t worry though; they’re all highly
customizable, so you can adjust them to fit your needs.

Each extension focuses on a single feature and comes with its own documentation
that explains how to set it up and use it. If you’d like a quick overview along
with links to the docs for each extension, check out
the [Extensions Overview](docs/EXTENSIONS.md).

> #### Broken paths? {: .warning}
> The [Verified Routes extension](docs/EXTENSIONS.md#verified-routes) is
> configured to act as drop-in replacements. As a result you might have to
> rename some `~p` sigils (verified route paths) in (h)eex templates to `~o`
> where the default _non-branching_ behaviour is required.

## Help?

When you run into issues, please have a look at the
[Troubleshooting](docs/TROUBLESHOOTING.md) guide and
[Elixir Forum](https://elixirforum.com/tag/routex)
