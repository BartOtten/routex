defmodule Routex.Extension.AlternativeGetters do
  @moduledoc """
  Creates helper functions to get a list of alternative slugs and their Routex
  attributes by providing the function a binary url.

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
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
  [ %Routex.Extension.AlternativeGetters{
    slug: "products/12/?foo=baz",
    match?: true,
    attrs: %{
      __branch__: [0, 12, 0],
      __origin__: "/products/:id",
      [...attributes set by other extensions...]
    }},
    %Routex.Extension.AlternativeGetters{
    slug: "/europe/products/12/?foo=baz",
    match?: true,
    attrs: %{
      __branch__: [0, 12, 1],
      __origin__: "/products/:id",
      [...attributes set by other extensions...]
    }},
   %Routex.Extension.AlternativeGetters{
    slug: "/asia/products/12/?foo=baz",
    match?: true,
    attrs: %{
      __branch__: [0, 12, 1],
      __origin__: "/products/:id",
      [...attributes set by other extensions...]
    }},
  ]
  ```
  """
  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Matchable
  alias Routex.Route

  defstruct [:slug, :attrs, match?: false]

  @impl Routex.Extension
  def create_helpers(routes, _cm, _env) do
    prelude =
      quote do
        def alternatives(url) when is_binary(url) do
          uri = Matchable.new(url)
          alternatives(uri)
        end
      end

    functions =
      for {_nesting, siblings} <- Route.group_by_nesting(routes) do
        body_ast =
          for sibling <- siblings do
            map_ast(sibling)
          end

        _function_ast =
          for route <- siblings do
            route |> Matchable.new() |> Matchable.to_func(:alternatives, body_ast)
          end
      end

    [prelude, functions]
  end

  defp map_ast(route) do
    pattern = route |> Matchable.new() |> Matchable.to_pattern()
    attrs = Attrs.get(route)

    quote do
      %Routex.Extension.AlternativeGetters{
        match?: unquote(Macro.var(:pattern, Matchable)) == unquote(pattern),
        slug: unquote(pattern) |> Matchable.to_binary(),
        attrs: unquote(Macro.escape(attrs))
      }
    end
  end
end
