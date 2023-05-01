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

  use Routex.Extension
  alias Routex.Attrs
  alias Routex.Path

  @impl Routex.Extension
  def create_helpers(routes, _cm, _env) do
    prelude =
      quote do
        def attrs(url) when is_binary(url) do
          path = URI.parse(url).path
          segments = Path.split(path)
          attrs(segments)
        end
      end

    ast =
      for route <- routes do
        pattern = Path.build_path_match(route.path)

        quote do
          def attrs(unquote(pattern)) do
            unquote(route |> Attrs.get() |> Macro.escape())
          end
        end
      end

    [prelude | ast]
  end
end
