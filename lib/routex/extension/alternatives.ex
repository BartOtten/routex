defmodule Routex.Extension.Alternatives do
  @moduledoc """
  Creates alternative routes based on `scopes` configured in a Routex backend
  module. Scopes can be nested and each scope can provide `Routex.Attrs` to be shared
  with other extensions.

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  # This example uses a `Struct` for custom attributes, so there is no attribute inheritance;
  # only struct defaults. When using maps, nested scopes will inherit attributes from their parent.

  + defmodule ExampleWeb.RoutexBackend.AltAttrs do
  +  @moduledoc false
  +  defstruct [:contact, locale: "en"]
  + end

  defmodule ExampleWeb.RoutexBackend do
  + alias ExampleWeb.RoutexBackend.AltAttrs

  use Routex,
  extensions: [
  + Routex.Extension.Alternatives
  ],
  + scopes: %{
  +    "/" => %{
  +      attrs: %AltAttrs{contact: "root@example.com"},
  +      scopes: %{
  +        "/europe" => %{
  +          attrs: %AltAttrs{contact: "europe@example.com"},
  +          scopes: %{
  +            "/nl" => %{attrs: %AltAttrs{locale: "nl", contact: "verkoop@example.nl"}},
  +            "/be" => %{attrs: %AltAttrs{locale: "nl", contact: "handel@example.be"}}
  +          }
  +        },
  +      "/gb" => %{attrs: %AltAttrs{contact: "sales@example.com"}
  +    }
  +  }
  ```

  ## Pseudo result
                          ⇒ /products/:id/edit              locale: "en", contact: "rootexample.com"
      /products/:id/edit  ⇒ /europe/nl/products/:id/edit    locale: "nl", contact: "verkoop@example.nl"
                          ⇒ /europe/be/products/:id/edit    locale: "nl", contact: "handel@example.be"
                          ⇒ /gb/products/:id/edit           locale: "en", contact: "sales@example.com"

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - **any key/value in `:attrs`**
  - scope_helper
  - scope_alias
  - scope_prefix
  - scope_opts
  - alternatives (list of `Phoenix.Route.Route`)
  """
  use Routex.Extension
  alias Routex.Attrs
  alias Routex.Extension.Alternatives.Config
  alias Routex.Extension.Alternatives.Scopes
  alias Routex.Path
  alias Routex.Route

  @expandable_route_methods [
    :get,
    :post,
    :put,
    :patch,
    :delete,
    :options,
    :connect,
    :trace,
    :head,
    :live
  ]

  @impl Routex.Extension
  def configure(config, _backend) do
    scopes_nested = Scopes.add_precomputed_values!(config[:alternatives])
    expansion_config = Config.new!(scopes_nested: scopes_nested)

    [{:scopes, expansion_config.scopes} | config]
  end

  @impl Routex.Extension
  def transform(routes, backend, _env) do
    config = backend.config()

    routes =
      for route <- routes do
        if route.verb in @expandable_route_methods do
          route
          |> expand_route(config)
        else
          route
        end
      end

    List.flatten(routes)
  end

  @impl Routex.Extension
  def post_transform(routes, _cm, _env) do
    grouped = Route.group_by_path(routes)

    routes =
      for {_path, groutes} <- grouped, route <- groutes do
        Attrs.put(route, :alternatives, groutes)
      end

    List.flatten(routes)
  end

  defp expand_route(route, config) do
    for {{_scope, scope_opts}, suborder} <- Enum.with_index(config.scopes) do
      path = Path.add_prefix(route.path, scope_opts.scope_prefix)
      helper = helper_name(route.helper, scope_opts.scope_alias)

      %{route | path: path, helper: helper}
      |> Attrs.merge(scope_opts.attrs)
      |> Attrs.merge(scope_opts |> Map.from_struct() |> Map.delete(:attrs))
      |> Attrs.update(:__order__, &List.insert_at(&1, -1, suborder))
      |> Attrs.put(:scope_helper, scope_opts.attrs.scope_helper)
    end
  end

  defp helper_name(nil, _nil), do: nil
  defp helper_name(helper, nil), do: helper
  defp helper_name(helper, suffix), do: Enum.join([helper, "_", suffix])
end
