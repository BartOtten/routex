defmodule Routex.Extension.RouteHelpers do
  @moduledoc ~S"""
  This module provides route helpers that support the automatic selection of
  alternative routes. These helpers can serve as drop-in replacements for
  Phoenix's default route helpers.

  Use this extension only if your application leverages extensions that
  generate alternative routes. Otherwise, the result will be identical to the
  official helpers provided by Phoenix.

  ## Configuration

  In versions of Phoenix prior to 1.7, an alias `Routes` was created by
  default. You can either replace this alias or add an alias for
  `RoutexHelpers`. Note that Phoenix 1.7 and later have deprecated these
  helpers in favor of Verified Routes.

  In the example below, we override the default `Routes` alias to use Routex's
  Route Helpers as a drop-in replacement, while keeping the original helper
  functions available under the alias `OriginalRoutes`:

  ^^^diff
  # file /lib/example_web.ex
  defp routex_helpers do
  + alias ExampleWeb.Router.Helpers, as: OriginalRoutes
  + alias ExampleWeb.Router.RoutexHelpers, as: Routes
  end
  ^^^

  ## Pseudo Result

  When alternative routes are created, auto-selection is used to keep the user
  within a specific branch.

  ### Example in a (h)eex template:

  ^^^html
  <a href={Routes.product_index_path(@socket, :show, product)}>Product #1</a>
  ^^^

  ### Result after compilation:

  ^^^elixir
  case alternative do
     nil ⇒  "/products/#{product}"
    "en" ⇒  "/products/#{product}"
    "nl" ⇒  "/europe/nl/products/#{product}"
    "be" ⇒  "/europe/be/products/#{product}"
  end
  ^^^

  ## `Routex.Attrs`

  **Requires:**
  - None

  **Sets:**
  - None
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Route
  alias Routex.Types, as: T
  alias Routex.Utils

  @type helper_module :: module()

  @interpolate ":"

  @impl Routex.Extension
  @doc """
  Creates the route helpers for the given routes if the `:phoenix_helpers`
  attribute is set.

  ## Parameters
  - `routes`: The list of routes to create helpers for.
  - `backend`: The backend module (not used).
  - `env`: The macro environment.

  ## Returns
  A list of quoted expressions representing the generated helpers.
  """
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  def create_helpers(routes, backend, env) do
    if Utils.get_attribute(env.module, :phoenix_helpers, false) do
      do_create_helpers(routes, backend, env)
    else
      []
    end
  rescue
    _in_test_env -> do_create_helpers(routes, backend, env)
  end

  @pdoc """
  Internal function to create the route helpers for the given routes.
  """
  @spec do_create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  defp do_create_helpers(routes, _backend, env) do
    IO.write("\n")

    Routex.Utils.print(
      __MODULE__,
      "The use of RouteHelpers may cause long compilation times.\n"
    )

    routes_per_origin = Route.group_by_nesting(routes)

    mapped_routes_per_origin =
      for {origin, routes} <- routes_per_origin do
        routes =
          for route <- routes do
            %{
              private: %{routex: %{__branch__: Attrs.get(route, :__branch__)}},
              helper: route.helper
            }
          end

        {origin, routes}
      end
      |> Map.new()

    prelude =
      quote do
        defp from_origin(origin),
          do: Map.get(unquote(Macro.escape(mapped_routes_per_origin)), origin)

        defdelegate static_path(arg1, arg2), to: unquote(Module.concat(env.module, "Helpers"))
      end

    helpers_ast =
      for {origin, routes} <- routes_per_origin do
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

          if route.path == Attrs.get(route, :__origin__) do
            quote do
              unquote(
                dynamic_defmacro_with_arity(orig_fun_name, fn_args, [origin, router, suffix])
              )
            end
          else
            quote do
              unquote(dynamic_defdelegate_with_arity(orig_helper_module, orig_fun_name, fn_args))
            end
          end
        end
      end

    [prelude, helpers_ast]
  end

  @pdoc """
  Builds a case definition for the given routes and arguments.

  Called from templates during compilation
  """
  @doc false
  @spec build_case(list(any())) :: Macro.t()
  def build_case([caller, routes, router, suffix, args]) do
    cases = build_case_clauses(routes, router, suffix, args)
    helper_ast = Utils.get_helper_ast(caller)

    quote do
      case unquote(helper_ast) do
        [unquote_splicing(cases)]
      end
    end
  end

  @pdoc """
  Builds the case clauses for the given routes and arguments.
  """
  @spec build_case_clauses(T.routes(), T.backend(), String.t(), list(any())) :: T.ast()
  defp build_case_clauses(routes, router, suffix, args) do
    for route <- routes do
      ref = route |> Routex.Attrs.get(:__branch__) |> List.last()
      helper = (route.helper <> suffix) |> String.to_atom()
      helper_module = Module.concat(router, :Helpers)

      quote do
        unquote(ref) -> apply(unquote(helper_module), unquote(helper), unquote(args))
      end
    end
    |> List.flatten()
    |> Enum.uniq()
  end

  @pdoc """
  Generates a defmacro with the given name and arguments.

  Arguments are wrapped in a list for formatting purposes.
  """
  @spec dynamic_defmacro_with_arity(atom(), list(Macro.t()), list(any())) :: Macro.t()
  defp dynamic_defmacro_with_arity(fn_name, fn_args, [origin, router, suffix]) do
    quote do
      defmacro unquote(fn_name)(unquote_splicing(fn_args)) do
        args = [
          __CALLER__,
          from_origin(unquote(origin)),
          unquote(router),
          unquote(suffix),
          unquote(fn_args)
        ]

        # credo:disable-for-next-line
        Routex.Extension.RouteHelpers.build_case(args)
      end
    end
  end

  @pdoc """
  Generates a defdelegate with the given name and arguments.
  """
  @spec dynamic_defdelegate_with_arity(helper_module, atom(), list(Macro.t())) :: Macro.t()
  defp dynamic_defdelegate_with_arity(helper_module, fn_name, fn_args) do
    quote do
      defdelegate unquote(fn_name)(unquote_splicing(fn_args)), to: unquote(helper_module)
    end
  end

  _silence_unused = @pdoc
end
