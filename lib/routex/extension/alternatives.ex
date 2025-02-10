defmodule Routex.Extension.Alternatives do
  @moduledoc """
  Creates alternative routes based on `branches` configured in a Routex backend
  module. Branches can be nested and each branch can provide `Routex.Attrs` to be shared
  with other extensions.

  > #### In combination with... {: .neutral}
  > How to combine this extension for localization is written in de [Localization Guide](guides/LOCALIZED_ROUTES.md)

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  # This example uses a `Struct` for custom attributes, so there is no attribute inheritance;
  # only struct defaults. When using maps, nested branches will inherit attributes from their parent.

  + defmodule ExampleWeb.RoutexBackend.AltAttrs do
  +  @moduledoc false
  +  defstruct [:contact, locale: "en"]
  + end

  defmodule ExampleWeb.RoutexBackend do
  + alias ExampleWeb.RoutexBackend.AltAttrs

  use Routex.Backend,
  extensions: [
    Routex.Extension.AttrGetters, # required
  + Routex.Extension.Alternatives,
  Routex.Extension.AttrGetters
  ],
  + alternatives: %{
  +    "/" => %{
  +      attrs: %AltAttrs{contact: "root@example.com"},
  +      branches: %{
  +        "/europe" => %{
  +          attrs: %AltAttrs{contact: "europe@example.com"},
  +          branches: %{
  +            "/nl" => %{attrs: %AltAttrs{locale: "nl", contact: "verkoop@example.nl"}},
  +            "/be" => %{attrs: %AltAttrs{locale: "nl", contact: "handel@example.be"}}
  +          }
  +        },
  +      "/gb" => %{attrs: %AltAttrs{contact: "sales@example.com"}
  +    }
  +  },
  + alternatives_prefix: false  # whether to automatically prefix routes, defaults to true
  ```

  ## Pseudo result
  ```elixir
      Router              Generated                         Attributes
                          ⇒ /products/:id/edit              locale: "en", contact: "rootexample.com"
      /products/:id/edit  ⇒ /europe/nl/products/:id/edit    locale: "nl", contact: "verkoop@example.nl"
                          ⇒ /europe/be/products/:id/edit    locale: "nl", contact: "handel@example.be"
                          ⇒ /gb/products/:id/edit           locale: "en", contact: "sales@example.com"
   ```

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - **any key/value in `:attrs`**
  - branch_helper
  - branch_alias
  - branch_prefix
  - branch_opts
  - alternatives (list of `Phoenix.Route.Route`)
  """
  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Extension.Alternatives.Branches
  alias Routex.Extension.Alternatives.Config

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
    branches_nested = Branches.add_precomputed_values!(config[:alternatives])
    expansion_config = Config.new!(branches_nested: branches_nested)

    [{:branches, expansion_config.branches} | config]
  end

  @impl Routex.Extension
  def transform(routes, backend, _env) do
    config = backend.config()

    routes =
      for route <- routes do
        if route.verb in @expandable_route_methods, do: expand_route(route, config), else: route
      end

    List.flatten(routes)
  end

  defp expand_route(route, config) do
    global_prefix? = Map.get(config, :alternatives_prefix, true)

    for {{_branch, branch_opts}, suborder} <- Enum.with_index(config.branches) do
      path_prefix? = Map.get(route.private.routex, :alternatives_prefix, global_prefix?)

      path =
        if path_prefix? do
          Path.join(branch_opts.branch_prefix, route.path)
        else
          route.path
        end

      helper = helper_name(route.helper, branch_opts.branch_alias)

      %{route | path: path, helper: helper}
      |> Attrs.merge(branch_opts.attrs)
      |> Attrs.merge(branch_opts |> Map.from_struct() |> Map.delete(:attrs))
      |> Attrs.update(:__branch__, &List.insert_at(&1, -1, suborder))
      |> Attrs.put(:branch_helper, branch_opts.attrs.branch_helper)
    end
  end

  defp helper_name(nil, _nil), do: nil
  defp helper_name(helper, nil), do: helper
  defp helper_name(helper, suffix), do: Enum.join([helper, "_", suffix])
end
