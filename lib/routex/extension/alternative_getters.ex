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
  - alternatives(segments :: list, query:: String.t()) :: structs()

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
					uri = Routex.URI.to_matchable(url)
          alternatives(uri)
        end
      end

    sibling_groups = Route.group_by_nesting(routes)

    route_groups =
      routes
      |> Enum.group_by(& &1, &Map.get(sibling_groups, Route.get_nesting(&1)))

    funs =
      for {route, sibling_routes} <- route_groups do
        helper_ast(route, sibling_routes, :ignored)
      end |> Enum.reverse()

    [prelude | funs]
  end

  defp helper_ast(route, sibling_routes, _env) do
    pattern = route |> Routex.Route.to_matchable()
		

    dynamic_paths =
      sibling_routes
      |> List.flatten()
      |> Enum.map(fn route ->
        pattern =
          Routex.Path.to_match_pattern(route.path)

        # unset the :alternatives key as it is redundant
        attrs =
          route
          |> Attrs.get()
          |> Map.new()
          |> Map.drop([:alternatives])

        {pattern, Macro.escape(attrs)}
      end)

    result =
      quote do
        def alternatives(unquote(pattern)) do
          unquote(dynamic_paths)
          |> Enum.map(
            &%Routex.Extension.AlternativeGetters{
						slug: elem(&1, 0)
						|> Routex.Path.absname()
						|> Path.join() |> then(fn x -> x <> Enum.join(unquote(Macro.var(:tl, Routex.Path))) end),
              attrs: elem(&1, 1)
            }
          )
        end
      end

    result
  end
end
