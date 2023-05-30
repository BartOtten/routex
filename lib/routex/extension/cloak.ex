defmodule Routex.Extension.Cloak do
  @moduledoc """
  Transforms routes to be unrecognizable.

  This module is intended for testing and demonstration purposes. Do not use
  this for other purposes.

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex,
    extensions: [
  +   Routex.Extension.Cloak,
  ],
  ```

   ## Pseudo result
      /products/  ⇒ /c/1
      /products/:id/edit  ⇒ /c/:id/2      ⇒ in browser: /c/1/2, /c/2/2/ etc...
      /products/:id/show/edit  ⇒ /:id/3   ⇒ in browser: /c/1/3, /c/2/3/ etc...

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none
  """
  @behaviour Routex.Extension

  alias Routex.Path

  @interpolate ":"
  @catch_all "*"

  # original routes should be preserved until we figure out how to fix controllers
  # relying directly on verified routes

  #   warning: no route path for ExampleWeb.Router matches "/users/log_in"
  #   lib/example_web/user_auth.ex:213: ExampleWeb.UserAuth.require_authenticated_user/2

  # warning: no route path for ExampleWeb.Router matches "/users/log_in"
  #   lib/example_web/user_auth.ex:159: ExampleWeb.UserAuth.on_mount/4

  @impl Routex.Extension
  def transform(routes, _cm, _env) do
    {routes, _} =
      for {route, idx} <- Enum.with_index(routes, 0), reduce: {[], %{}} do
        {routes, cmap} ->
          if path = cmap[route.path] do
            route = %{route | path: path}
            {[route | routes], cmap}
          else
            dynamics =
              route.path
              |> Path.split()
              |> Enum.filter(&(&1 === @catch_all || String.starts_with?(&1, @interpolate)))

            static =
              if idx == 0 do
                "/"
              else
                idx
              end

            path = Path.join(["c", dynamics, static])
            cmap = Map.put_new(cmap, route.path, path)
            route = %{route | path: path}

            {[route | routes], cmap}
          end
      end

    routes
  end
end
