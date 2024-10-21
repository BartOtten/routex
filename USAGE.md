# Usage

## Requirements

- Elixir >=1.11
- Phoenix >= 1.6.0
- Phoenix LiveView >= 0.16 (optional)


## Installation

You can install this library by adding it to your list of dependencies in `mix.exs`:

```diff
def deps do
  [
     ...other deps
+    {:routex, ">= 0.0.0"}
  ]
end
```

Modify the entrypoint your web interface definition.
```diff
# file: lib/example_web.ex

+  use Routex.Router  # always before Phoenix Router
   use Phoenix.Router, helpers: true

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
+      import unquote(__MODULE__).Router.RoutexHelpers, only: :macros
+      alias unquote(__MODULE__).Router.RoutexHelpers, as: Routes
+    end
+  end
```

The `on_mount` hook attaches a `handle_param` which in turn assigns a few
(helper) values to the connection and/or socket. This includes the current url
and any assigns created by Routex Extensions. When you want to have full control
over these hooks, you can use something like the snippet below instead.

```elixir
def on_mount(_, params, session, socket) do
  socket =
    Phoenix.LiveView.attach_hook(socket, :set_rtx, :handle_params, fn _params, url, socket ->
      attrs = ExampleWeb.Route.RoutexHelpers.attrs(url)
      rtx_assigns = [url: url, __order__: attrs.__order__] ++ Map.to_list(attrs.assigns)

      {:cont,Phoenix.LiveView.assign( socket, rtx_assigns)}
    end)

  {:cont, socket}
end
```

## Configuration

To use `Routex`, a module that calls `use Routex.Backend` (referred to below as a
"backend") has to be defined. It includes a list with extensions and
configuration of extensions.

```elixir
defmodule ExampleWeb.RoutexBackend do
use Routex.Backend,
  extensions: [
  # ...list of extensions...
  ],
end
```

## Extensions

Routex is merely a framework and relies on extensions to provide features. Each
extension provides a single feature. The extensions have their own documentation
which specifies how to configure and use them.

## Preprocess routes with Routex

`Routex` will preprocess any route wrapped in a `preprocess_using` block; either
direct or indirect. It uses the backend passed as the first argument.  This
allows the use of multiple backends (e.g. to use different extensions for admin
routes)

```diff
# file: router.ex
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

When you run into issues, please have a look at the [Troubleshooting](TROUBLESHOOTING.md)

