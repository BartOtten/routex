defmodule Routex.Extension.AlternativeGetters do
  @moduledoc """
  Creates helper functions to get a list of alternative slugs and their routes
  attributes given a binary url or a list of path segments and a binary url.

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex,
    extensions: [
  +   Routex.Extension.AlternativeGetters,
  ],
  ```

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none

  ## Helpers
  - alternatives(url :: String.t()) :: struct()

  **Example**
  ```elixir
  iex> ExampleWeb.Router.RoutexHelpers.alternatives("/products/12?foo=baz")
  [
    %Routex.Extension.AlternativeGetters{
    slug: "/europe/products/12/?foo=baz",
    attrs: %{
      __line__: 32,
      __order__: [0, 12, 1],
      __origin__: "/products/:id",
      [...attributes set by other extensions...]
    }},
   %Routex.Extension.AlternativeGetters{
    slug: "/asia/products/12/?foo=baz",
    attrs: %{
      __line__: 32,
      __order__: [0, 12, 1],
      __origin__: "/products/:id",
      [...attributes set by other extensions...]
    }},
  ]
  ```
  """
  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Route

  defstruct [:slug, :attrs]

  @impl Routex.Extension
  def create_helpers(routes, _cm, _env) do
    prelude =
      quote do
        def alternatives(url) when is_binary(url) do
          uri = Routex.Match.new(url)
          alternatives(uri)
        end
      end

    functions = functions_ast(routes)

    [prelude, functions]
  end

  def functions_ast(routes) do
    sibling_groups = Route.group_by_nesting(routes)

    route_groups =
      routes
      |> Enum.group_by(& &1, &Map.get(sibling_groups, Route.get_nesting(&1)))

    for {route, sibling_routes} <- route_groups do
      function_ast(route, sibling_routes)
    end
    |> Enum.reverse()
  end

  defp function_ast(route, sibling_routes) do
    alternatives =
      sibling_routes
      |> List.flatten()
      |> Enum.map(fn route ->
        pattern = route |> Routex.Match.new() |> Routex.Match.to_pattern()

        # unset the :alternatives key when present as it is redundant
        attrs =
          route
          |> Attrs.get()
          |> Map.new()
          |> Map.drop([:alternatives])

        quote do
          %Routex.Extension.AlternativeGetters{
            slug: unquote(pattern) |> Routex.Match.to_binary(),
            attrs: unquote(attrs |> Macro.escape())
          }
        end
      end)

    route
    |> Routex.Match.new()
    |> Routex.Match.to_func(:alternatives, alternatives)
  end
end
