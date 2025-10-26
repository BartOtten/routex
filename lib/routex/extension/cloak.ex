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
  guess where `/90/!!` brings to?


  ## Options
  - `cloak`: Binary to duplicate or tuple with {module, function, arguments} which will receive a
  index counter as first argument.


  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
     Routex.Extension.AttrGetters, # required
  +  Routex.Extension.Cloak
  ],
  cloak: "!"
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

  alias Routex.Types, as: T

  @interpolate ":"
  @catch_all "*"

  def default_transform("/", _idx, _opt), do: []
  def default_transform(_path, idx, _opt), do: [to_string(idx)]

  def binary_transform("/", _idx, _binary), do: []
  def binary_transform(_path, idx, binary), do: [String.duplicate(binary, idx + 1)]

  def function_transform("/", _idx, _mfa), do: []
  def function_transform(path, idx, {m, f, a}), do: apply(m, f, [path, idx | a])

  @impl Routex.Extension
  @spec configure(T.opts(), T.backend()) :: T.opts()
  def configure(config, _backend) do
    opt = Keyword.get(config, :cloak)

    transform_mfa =
      cond do
        is_binary(opt) -> {__MODULE__, :binary_transform, [opt]}
        is_tuple(opt) -> {__MODULE__, :function_transform, [opt]}
        is_nil(opt) -> {__MODULE__, :default_transform, [opt]}
      end

    Keyword.put(config, :cloak_transform, transform_mfa)
  end

  @impl Routex.Extension
  @spec transform(T.routes(), T.backend(), T.env()) :: T.routes()
  def transform(routes, backend, _env) do
    {cm, cf, ca} = backend.config().cloak_transform

    routes
    |> Enum.with_index()
    |> Enum.reduce({[], %{}}, fn {route, idx}, {routes, cloak_map} ->
      if path = cloak_map[route.path] do
        route = %{route | path: path}
        {[route | routes], cloak_map}
      else
        dynamics =
          route.path
          |> Path.split()
          |> Enum.filter(&(&1 === @catch_all || String.starts_with?(&1, @interpolate)))

        static = apply(cm, cf, [route.path, idx | ca])

        path = ["/", dynamics, static] |> Path.join() |> Path.absname()
        cloak_map = Map.put_new(cloak_map, route.path, path)
        route = %{route | path: path}

        {[route | routes], cloak_map}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end
end
