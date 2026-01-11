defmodule Routex.Extension.AttrGetters do
  @moduledoc """
  Access route attributes at runtime within your controllers, plugs, or LiveViews
  based on the matched route's properties. Uses pattern matching for optimal
  performance during runtime.

  This extension provides the required `attrs/1` helper function, used by
  Routex to assign helper attributes in the generated `on_mount/4` callback.

  > #### In combination with... {: .neutral}
  > Other extensions set `Routex.Attrs`. The attributes an extension sets is listed in it's documentation.
  > To define custom attributes for routes have a look at `Routex.Extension.Alternatives`


  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
  +   Routex.Extension.AttrGetters,  # required
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
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Matchable
  alias Routex.Types, as: T

  @impl Routex.Extension
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  def create_helpers(routes, _backend, _env) do
    guarded_defs =
      quote do
        require Record

        @doc """
        Returns Routex attributes of given URL
        """
        @spec attrs(url :: binary()) :: T.attrs()
        def attrs(url) when is_binary(url), do: url |> Matchable.new() |> do_attrs()
        def attrs(input) when Record.is_record(input, :matchable), do: do_attrs(input)
      end

    unguarded_defs =
      routes
      |> Enum.map(&to_pattern_and_body/1)
      |> Enum.uniq_by(fn {pattern, _body} -> pattern end)
      |> Enum.map(fn {pattern, body} ->
        quote do
          defp do_attrs(unquote(pattern) = patten), do: unquote(body)
        end
      end)

    [guarded_defs | unguarded_defs]
  end

  defp to_pattern_and_body(route) do
    pattern =
      route
      |> Matchable.new()
      |> Matchable.to_pattern()

    body =
      route
      |> Attrs.get()
      |> Macro.escape()

    {pattern, body}
  end
end
