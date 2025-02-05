defmodule Routex.Extension.AttrGetters do
  @moduledoc """
  Creates helper functions to get the `Routex.Attrs` given a binary url or a
  list of path segments. Use this to lazy load attributes instead of adding them
  upfront to assigns.

  > #### In combination with... {: .neutral}
  > Other extensions set `Routex.Attrs`. The attributes an extension sets is listed in it's documentation.
  > To define custom attributes for routes have a look at `Routex.Extension.Alternatives`


  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
  +   Routex.Extension.AttrGetters,
  ],
  ```

  ## Pseudo result
  ```elixir
  iex> ExampleWeb.Router.RoutexHelpers.attrs("/europe/nl/producten/?foo=baz")
  %{
    __branch__: [0, 9, 3],
    __origin__: "/products",
    backend: ExampleWeb.LocalizedRoutes,
    contact: "verkoop@example.nl",
    locale: "nl",
    branch_name: "The Netherlands",
    branch_helper: "europe_nl",
  }
  ```

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none

  ## Helpers
  - attrs(url :: binary) :: map()
  - attrs(segments :: list) :: map()
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Matchable

  @impl Routex.Extension
  def create_helpers(routes, _backend, _env) do
    prelude =
      quote do
        @doc """
        Returns Routex attributes of given URL
        """
        def attrs(url) when is_binary(url) do
          url
          |> Matchable.new()
          |> attrs()
        end
      end

    functions =
      for route <- routes do
        attributes = route |> Attrs.get() |> Macro.escape()

        route
        |> Matchable.new()
        |> Matchable.to_func(:attrs, attributes)
      end

    [prelude, functions]
  end
end
