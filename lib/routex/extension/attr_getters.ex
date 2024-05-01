defmodule Routex.Extension.AttrGetters do
  @moduledoc """
  Creates helper functions to get the `Routex.Attrs` given a binary url or a
  list of path segments. This way the attributes for route can be lazily
  loaded.

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex,
    extensions: [
  +   Routex.Extension.AttrGetters,
  ],
  ```

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none

  ## Helpers
  - attrs(url :: binary) :: map()
  - attrs(segments :: list) :: map()

  **Example**
  ```elixir
  iex> ExampleWeb.Router.RoutexHelpers.attrs("/europe/nl/producten/?foo=baz")
  %{
    __line__: 28,
    __order__: [0, 9, 3],
    __origin__: "/products",
    backend: ExampleWeb.LocalizedRoutes,
    contact: "verkoop@example.nl",
    locale: "nl",
    scope_name: "The Netherlands",
    scope_helper: "europe_nl",
  }
  ```
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Path
  #alias Routex.MatchMap

  @impl Routex.Extension
  def create_helpers(routes, _cm, _env) do
    prelude =
      quote do
        @doc """
        Returns Routex attributes of given URL
        """
        def attrs(url) when is_binary(url) do
          url
          |> Routex.URI.to_matchable()
          |> attrs()
        end
      end

    case_clauses =
      for route <- routes do
        pattern = Routex.Route.to_matchable(route)
				
        quote do
          unquote(pattern) ->
            unquote(route |> Attrs.get() |> Macro.escape())
        end
      end
      |> List.flatten()

    ast =
      quote do
        def attrs(match) do
          case match do
            unquote(case_clauses)
          end
        end
      end

		#Routex.Dev.esc_inspect(ast)
		
    [prelude, ast]
  end
end
