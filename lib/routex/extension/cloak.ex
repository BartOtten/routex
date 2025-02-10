defmodule Routex.Extension.Cloak do
  @moduledoc """
  Transforms routes to be unrecognizable.


  > #### Warning {: .warning}
  >
  > This extension is intended for testing and demonstration. It may change at
  > any given moment to generate other routes without prior notice.


  The Cloak extension demonstrates how Routex enables extensions to transform
  routes beyond recognition without breaking Phoenix' native and Routex' routing
  features.

  Currently it numbers all routes. Starting at 1 and incremening the counter for
  each route. It also shifts the parameter to the left; causing a chaotic route
  structure.

  Do note: this still works with the Verified Routes extension. You can use the
  original, non transformed, routes in templates (e.g. `~p"/products/%{product}"`)
  and still be sure the transformed routes rendered at runtime (e.g. `/88/2` when product.id = 88)
  are valid routes.

  ## Do (not) try this at home
  - Try this extension with a route generating extension like
  `Routex.Extension.Alternatives` for even more chaos.

  - Adapt this extension to use character repetition instead of numbers. Can you
  guess where `/90/**` leads to?


  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
     Routex.Extension.AttrGetters, # required
  +  Routex.Extension.Cloak
  ],
  ```

  ## Pseudo result
      Original                 Rewritten    Result (product_id: 88, 89, 90)
      /products                ⇒     /1     ⇒    /1
      /products/:id/edit       ⇒ /:id/2     ⇒ /88/2, /89/2, /90/2 etc...
      /products/:id/show/edit  ⇒ /:id/3     ⇒ /88/3, /89/3, /90/3 etc...


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
