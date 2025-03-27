defmodule Routex.Extension.Assigns do
  @moduledoc """
  Extracts `Routex.Attrs` from a route and makes them available in components
  and controllers with the assigns operator `@` (optionally under a namespace).

  > #### In combination with... {: .neutral}
  > Other extensions set `Routex.Attrs`. The attributes an extension sets is listed in it's documentation.
  > To define custom attributes for routes have a look at `Routex.Extension.Alternatives`


  ## Options
  - `namespace`: when set creates a named collection: assigns available as @namespace.key
  - `attrs`: If attrs is not set, all Routex.Attrs are included. If attrs is set
    to a list of keys, only the specified subset of attributes will be
    available.

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

  alias Routex.Types, as: T

  @impl Routex.Extension
  @spec post_transform(T.routes(), T.backend(), T.env()) :: T.routes()
  def post_transform(routes, backend, _env) do
    config = backend.config()
    namespace = get_in(config, [Access.key(:assigns), :namespace])
    to_be_assigned = get_in(config, [Access.key(:assigns), :attrs])

    for route <- routes do
      attributes = Routex.Attrs.get(route)

      assigns =
        attributes
        |> into_assigns(to_be_assigned)
        |> maybe_namespace(namespace)

      route
      |> Routex.Attrs.put(%{assigns: assigns})
      |> update_assigns(assigns)
    end
  end

  defp into_assigns(attrs, nil), do: attrs

  defp into_assigns(attrs, to_be_assigned),
    do: Map.take(attrs, to_be_assigned)

  defp maybe_namespace(assigns, nil), do: assigns

  defp maybe_namespace(assigns, namespace), do: Map.put(%{}, namespace, assigns)

  defp update_assigns(%{assigns: nil} = route, new),
    do: Map.put(route, :assigns, new)

  defp update_assigns(%{assigns: old} = route, new),
    do: Map.put(route, :assigns, Map.merge(old, new))

  @doc """
  Hook attached to the `handle_params` stage in the LiveView life cycle
  """
  def handle_params(_params, _uri, socket, attrs \\ %{}) do
    assigns = Map.get(attrs, :assigns, %{})
    socket = Phoenix.Component.assign(socket, assigns)

    {:cont, socket}
  end
end
