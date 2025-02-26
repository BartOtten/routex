defmodule Routex.Extension.Assigns do
  @moduledoc """
  Extracts `Routex.Attrs` from a route and makes them available in components
  and controllers with the assigns operator `@` (optionally under a namespace).

  > #### In combination with... {: .neutral}
  > Other extensions set `Routex.Attrs`. The attributes an extension sets is listed in it's documentation.
  > To define custom attributes for routes have a look at `Routex.Extension.Alternatives`


  ## Options
  - `namespace`: when set creates a named collection of `Routex.Attrs`
  - `attrs`: when set defines keys of `Routex.Attrs` to make available

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
      Routex.Extension.AttrGetters, # required
  +   Routex.Extension.Assigns
  ],
  + assigns: %{namespace: :rtx, attrs: [:branch_helper, :locale, :contact, :name]}
  ```

  ## Pseudo result
      # in (h)eex template
      @rtx.branch_helper  ⇒  "eu_nl"
      @rtx.locale         ⇒  "nl"
      @rtx.contact        ⇒  "verkoop@example.nl"
      @rtx.name           ⇒  "The Netherlands"

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - assigns

  ## Example use case
  Combine with `Routex.Extension.Alternatives` to make compile time, branch
  bound assigns available to components and controllers.
  """

  @behaviour Routex.Extension

  @impl Routex.Extension
  def post_transform(routes, backend, _env) do
    config = backend.config()
    namespace = get_in(config, [Access.key(:assigns), :namespace])
    attrs = get_in(config, [Access.key(:assigns), :attrs])

    for route <- routes do
      assigns =
        route
        |> Routex.Attrs.get()
        |> Enum.reduce([], fn el = {k, _v}, acc ->
          if is_nil(attrs) or k in attrs, do: [el | acc], else: acc
        end)

      assigns_map =
        if namespace == nil do
          %{assigns: Map.new(assigns)}
        else
          %{assigns: Map.new([{namespace, Map.new(assigns)}])}
        end

      Routex.Attrs.merge(route, assigns_map)
    end
  end

  @doc """
  Hook attached to the `handle_params` stage in the LiveView life cycle
  """
  @impl Routex.Extension
  def handle_params(_params, _uri, socket, attrs \\ %{}) do
    assigns = Map.get(attrs, :assigns, %{})
    socket = Phoenix.Component.assign(socket, assigns)

    {:cont, socket}
  end

  @doc """
  Plug added to the Plug pipeline
  """
  @impl Routex.Extension
  def plug(conn, _opts, attrs \\ %{}) do
    assigns = Map.get(attrs, :assigns, [])
    Plug.Conn.merge_assigns(conn, assigns)
  end
end
