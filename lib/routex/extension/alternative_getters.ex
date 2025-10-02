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

  alias Routex.Matchable
  alias Routex.Route
  alias Routex.Types, as: T

  defstruct [:slug, :attrs, match?: false]

  @impl Routex.Extension
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  def create_helpers(routes, _backend, _env) do
    guarded_defs =
      quote do
        require Record
        def alternatives(url) when is_binary(url), do: url |> Matchable.new() |> do_alternatives()

        def alternatives(input) when Record.is_record(input, Matchable),
          do: input |> do_alternatives()
      end

    unguarded_defs =
      routes
      |> Route.group_by_nesting()
      |> Enum.flat_map(&to_pattern_and_body/1)
      |> Enum.uniq_by(fn {pattern, _body} -> pattern end)
      |> Enum.map(fn {pattern, body} ->
        quote do
          def do_alternatives(unquote(pattern) = pattern), do: unquote(body)
        end
      end)

    [guarded_defs | unguarded_defs]
  end

  defp to_pattern_and_body({_nesting, siblings}) do
    clause_body_ast = Enum.map(siblings, &clause_body/1)
    siblings |> Enum.map(&clause_pattern_body(&1, clause_body_ast))
  end

  defp clause_pattern_body(route, body_ast) do
    pattern = route |> Matchable.new() |> Matchable.to_pattern()
    {pattern, body_ast}
  end

  defp clause_body(route) do
    dynamic_slash_pattern = route |> Matchable.new() |> Matchable.to_pattern()

    static_slash_pattern =
      route |> Matchable.new() |> Matchable.to_pattern(strict_trailing?: true)

    quote do
      %Routex.Extension.AlternativeGetters{
        match?: unquote(dynamic_slash_pattern) == pattern,
        slug: unquote(static_slash_pattern) |> to_string(),
        attrs: unquote(dynamic_slash_pattern) |> to_string() |> attrs()
      }
    end
  end
end
