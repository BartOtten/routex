defmodule Routex.Extension.Assigns do
  @moduledoc """
  Extracts `Routex.Attrs` from the route and makes them available in components
  and controllers with the `@` assigns operator (optionally under a namespace).

  ## Options
  - `namespace`: when set creates a named collection of `Routex.Attrs`
  - `attrs`: when set defines keys of `Routex.Attrs` to make available

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex,
    extensions: [
  +   Routex.Extension.Assigns,
  ],
  + assigns: %{namespace: :rtx, attrs: [:scope_helper, :locale, :contact, :name]}
  ```

  ## Pseudo result
      # in (h)eex template
      @rtx.scope_helper   ⇒  "eu_nl"
      @rtx.locale         ⇒  "nl"
      @rtx.contact        ⇒  "verkoop@example.nl"
      @rtx.name           ⇒  "The Netherlands"

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - assigns

  ## Example use case
  Combine with `Routext.Extension.Alternatives` to make compile time, scope
  bound assigns available to components and controllers.
  """

  use Routex.Extension

  @impl Routex.Extension
  def post_transform(routes, cm, _env) do
    config = cm.config()
    namespace = get_in(config, [Access.key(:assigns), :namespace])
    attrs = get_in(config, [Access.key(:assigns), :attrs])

    for route <- routes do
      assigns =
        Enum.reduce(route.private.routex, [], fn el = {k, _v}, acc ->
          if is_nil(attrs) or k in attrs, do: [el | acc], else: acc
        end)

      assigns_map =
        if namespace == nil do
          %{assigns: Map.new(assigns)}
        else
          %{assigns: Map.new([{namespace, Map.new(assigns)}])}
        end

      # using direct manipulation
      %{
        route
        | private: Map.put(route.private, :routex, Map.merge(route.private.routex, assigns_map))
      }
    end
  end
end
