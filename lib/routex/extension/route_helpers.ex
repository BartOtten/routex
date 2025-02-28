defmodule Routex.Extension.RouteHelpers do
  @moduledoc ~S"""
  Provides route helpers with support for automatic selecting alternatives
  routes. The helpers can be used to override Phoenix' defaults as they are
  a drop-in replacements.

  Only use this extension when you make use of extensions generating alternative
  routes, as otherwise the result will be the same as the official helpers.

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
      Routex.Extension.AttrGetters,  # required
  +   Routex.Extension.RouteHelpers
  ],
  ```

  Phoenix < 1.7 created an alias `Routes` by default. You can either replace it
  or add an alias for RoutexHelpers. Phoenix >= 1.7 deprecated the helpers
  in favor of Verified Routes.

  In the example below we 'override' the default `Routes` alias to use
  Routex' Route Helpers as a drop-in replacement, but keep the original helpers
  functions available by using alias `OriginalRoutes`.


  ```diff
  # file /lib/example_web.ex
  defp routex_helpers do

  + alias ExampleWeb.Router.Helpers, as: OriginalRoutes
  + alias ExampleWeb.Router.RoutexHelpers, as: Routes

  end
  ```

  ## Pseudo result
      # When alternatives are created it uses auto-selection to keep the user 'in branch'.

      # in (h)eex template
      <a href={Routes.product_index_path(@socket, :show, product)}>Product #1</a>

      # is replaced during during compilation with:
      case alternative do
         nil ⇒  "/products/#{product}"
        "en" ⇒  "/products/#{product}"
        "nl" ⇒  "/europe/nl/products/#{product}"
        "be" ⇒  "/europe/be/products/#{product}"
      end

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Route
  alias Routex.Utils

  require Logger

  @interpolate ":"

  @impl Routex.Extension
  def create_helpers(routes, _backend, env) do
    IO.write("\n")

    Routex.Utils.print(
      __MODULE__,
      "The use of RouteHelpers may cause long compilation times.\n"
    )

    routes_per_origin = Route.group_by_nesting(routes)

    prelude =
      quote do
        defdelegate static_path(arg1, arg2), to: unquote(Module.concat(env.module, "Helpers"))
      end

    helpers_ast =
      for {_origin, routes} <- routes_per_origin do
        esc_routes = Macro.escape(routes)
        router = env.module

        for nr <- [2, 3],
            suffix <- ["_path", "_url"],
            route <- routes,
            route.helper != nil do
          nr_bindings =
            route.path |> Path.split() |> Enum.count(&String.starts_with?(&1, @interpolate))

          orig_fun_name = (route.helper <> suffix) |> String.to_atom()
          arity = nr + nr_bindings

          fn_args = Macro.generate_unique_arguments(arity, __MODULE__)
          orig_helper_module = Module.concat(router, :Helpers)

          case {route.path == Attrs.get(route, :__origin__), route.plug == Phoenix.LiveView.Plug} do
            {false, _lv?} ->
              quote do
                unquote(dynamic_delegate_with_arity(orig_helper_module, orig_fun_name, fn_args))
              end

            {true, _lv?} ->
              quote do
                unquote(
                  dynamic_fn_with_arity(orig_fun_name, fn_args, [esc_routes, router, suffix])
                )
              end
          end
        end
      end

    [prelude, helpers_ast]
  end

  def build_case([[caller, routes, router, suffix], args]) do
    cases = build_case_clauses(routes, router, suffix, args)
    helper_ast = Utils.get_helper_ast(caller)

    quote do
      case unquote(helper_ast) do
        unquote(cases)
      end
    end
  end

  def build_case_clauses(routes, router, suffix, args) do
    for route <- routes do
      ref = route |> Attrs.get(:__branch__) |> List.last()
      helper = (route.helper <> suffix) |> String.to_atom()
      helper_module = Module.concat(router, :Helpers)

      quote do
        unquote(ref) -> apply(unquote(helper_module), unquote(helper), unquote(args))
      end
    end
    |> List.flatten()
    |> Enum.uniq()
  end

  def dynamic_fn_with_arity(fn_name, fn_args, opts) do
    quote do
      defmacro unquote(fn_name)(unquote_splicing(fn_args)) do
        base_args = [__CALLER__ | unquote(opts)]
        args = [base_args, [unquote_splicing(fn_args)]]

        # credo:disable-for-next-line
        Routex.Extension.RouteHelpers.build_case(args)
      end
    end
  end

  def dynamic_delegate_with_arity(helper_module, fn_name, fn_args) do
    quote do
      defdelegate unquote(fn_name)(unquote_splicing(fn_args)), to: unquote(helper_module)
    end
  end
end
