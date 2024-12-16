defmodule Routex.Extension.Cloak do
  @moduledoc """
  Transforms routes to be unrecognizable.


  > #### Warning {: .warning}
  >
  > This extension is intended for testing and demonstration. It's
  > behavior may change over time.


  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
  +  Routex.Extension.Cloak,
     Routex.Extension.AttrGetters
  ],
  ```

   ## Pseudo result
      /products/  ⇒ /1
      /products/:id/edit  ⇒ rewrite: /:id/02      ⇒ in browser: /1/02, /2/02/ etc...
      /products/:id/show/edit  ⇒ rewrite: /:id/03   ⇒ in browser: /1/03, /2/03/ etc...

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none
  """
  @behaviour Routex.Extension

  @interpolate ":"
  @catch_all "*"

  @impl Routex.Extension
  def transform(routes, _backend, _env) do
    {routes, _} =
      for {route, idx} <- Enum.with_index(routes, 0), reduce: {[], %{}} do
        {routes, cloak_map} ->
          if path = cloak_map[route.path] do
            route = %{route | path: path}
            {[route | routes], cloak_map}
          else
            dynamics =
              route.path
              |> Path.split()
              |> Enum.filter(&(&1 === @catch_all || String.starts_with?(&1, @interpolate)))

            static =
              if idx == 0 do
                []
              else
                [to_string(idx)]
              end

            path = ["/", dynamics, static] |> Path.join() |> Path.absname()
            cloak_map = Map.put_new(cloak_map, route.path, path)
            route = %{route | path: path}

            {[route | routes], cloak_map}
          end
      end

    routes
  end
end
