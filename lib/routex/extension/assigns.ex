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
        Enum.reduce(route.private.routex, [], fn el = {k, _v}, acc ->
          if is_nil(attrs) or k in attrs, do: [el | acc], else: acc
        end)

      assigns_map =
        if namespace == nil do
          %{assigns: Map.new(assigns)}
        else
          %{assigns: Map.new([{namespace, Map.new(assigns)}])}
        end

      # duplicated for easy access in conn while also providing it as an Attr
      %{
        route
        | private: Map.put(route.private, :routex, Map.merge(route.private.routex, assigns_map)),
          assigns: Map.merge(route.assigns || %{}, assigns_map.assigns)
      }
    end
  end
end
