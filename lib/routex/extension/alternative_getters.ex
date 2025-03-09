defmodule Routex.Extension.AlternativeGetters do
  @moduledoc """
  Creates helper functions to get a list of maps alternative slugs and their `Routex.Attrs`
  by providing a binary url. Sets `match?: true` for the url matching record.

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
      Routex.Extension.AttrGetters, # required
      Routex.Extension.Alternatives,
  +   Routex.Extension.AlternativeGetters
  ],
  ```

  ## Usage example
  ```elixir
  <!-- @url is made available by Routex -->
  <!-- alternatives/1 is located in ExampleWeb.Router.RoutexHelpers aliased as Routes -->
  <.link
     :for={alternative <- Routes.alternatives(@url)}
     class="button"
     rel="alternate"
     hreflang={alternative.attrs.locale}
     patch={alternative.slug}
   >
     <.button class={(alternative.match? && "highlighted") || ""}>
       <%= alternative.attrs.display_name %>
     </.button>
   </.link>
  ```

  ## Pseudo result
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
    match?: false,
    attrs: %{
      __branch__: [0, 12, 1],
      __origin__: "/products/:id",
      [...attributes set by other extensions...]
    }},
   %Routex.Extension.AlternativeGetters{
    slug: "/asia/products/12/?foo=baz",
    match?: false,
    attrs: %{
      __branch__: [0, 12, 1],
      __origin__: "/products/:id",
      [...attributes set by other extensions...]
    }},
  ]
  ```

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none

  ## Helpers
  - alternatives(url :: String.t()) :: struct()

  """
  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Matchable
  alias Routex.Route
  alias Routex.Types, as: T

  defstruct [:slug, :attrs, match?: false]

  @impl Routex.Extension
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  def create_helpers(routes, _backend, _env) do
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
        slug: unquote(pattern) |> Matchable.to_string(),
        attrs: unquote(Macro.escape(attrs))
      }
    end
  end
end
