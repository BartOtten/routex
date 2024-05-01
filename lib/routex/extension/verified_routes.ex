defmodule Routex.Extension.VerifiedRoutes do
  @moduledoc ~S"""
  Provides support for branching routes with compile-time verification. This
  allows the use of the original route paths in controllers and templates.

  > #### Implementation summary {:.info}
  > Each sigil and function eventualy delegates to the official
  > `Phoenix.VerifiedRoutes`.  If a non-branching route is provided it will
  > simply delegate to the official Phoenix function. If a branching route is
  > provided, it will use a branching mechanism before delegation.

  ## Alternative Verified Route sigil
  Provides a sigil (default: ~l) to verify branching routes. The sigil to use
  can be set to ~p to override the default of Phoenix as it is a drop-in
  replacement. If you choose to override the default Phoenix sigil, this
  original sigil is renamed (default: ~o).

  ## Variants of url/{2,3,4} and path/{2,3}
  Provides branching variants of (and delegates to) functions provided by
  `Phoenix.VerifiedRoutes`. Both functions detect whether branching should be
  applied.

  ## Options
  - `verified_sigil_routex`: Sigil to use for Routex verified routes (default "~l")
  - `verified_sigil_original`: Sigil for original routes when `verified_sigil_routex`
    is set to "~p". (default: "~o")

  When `verified_sigil_routex` is set to "~p" an additional change must be made.

  ```diff
  # file /lib/example_web.ex
  defp routex_helpers do
  + import Phoenix.VerifiedRoutes, only: :functions
    import ExampleWeb.Router.Routex
  end
  ```

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex,
    extensions: [
  +   Routex.Extension.VerifiedRoutes,
  ],
  + verified_sigil_routex: "~p",
  + verified_sigil_original: "~o",
  ```

  ## Pseudo result (simplified)
      # given Routex is configured to use ~l
      # given Phoenix is assigned ~o (for example clarity)

      # given other extensions has provided transformations
      ~o"/products/#{product}"   ⇒  ~p"/products/#{products}"
      ~l"/products/#{product}"   ⇒  ~p"/transformed/products/#{product}"

      # given another extension has generated branches / alternative routes
      ~o"/products/#{product}"  ⇒  ~p"/products/#{products}"

      ~l"/products/#{product}"  ⇒
              case branch do
                nil ⇒  ~p"/products/#{product}"
                "en" ⇒  ~p"/products/en/#{product}"
                "eu_nl" ⇒  ~p"/europe/nl/products/#{product}"
                "eu_be" ⇒  ~p"/europe/be/products/#{product}"
              end

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none
  """

  alias Routex.Attrs
  alias Routex.ExtensionUtils
  alias Routex.Path
  alias Routex.Route

  require Phoenix.VerifiedRoutes
  require Logger

  @behaviour Routex.Extension
  @phoenix_sigil "~p"
  @default_verified_sigil_routex "~l"
  @default_verified_sigil_original "~o"

  @impl Routex.Extension
  def configure(config, cm) do
    routex = Keyword.get(config, :verified_sigil_routex, @default_verified_sigil_routex)
    original = Keyword.get(config, :verified_sigil_original, @default_verified_sigil_original)

    p1 =
      if routex == @phoenix_sigil do
        "\nThe default sigil used by Phoenix Verified Routes is overridden by Routex due to the configuration in `#{inspect(cm)}`.

      #{routex}: localizes and verifies routes. (override)
      #{original}: only verifies routes. (original)"
      else
        "\nRoutes can be localized using the #{routex} sigil"
      end

    p2 = "\n\nDocumentation: https://hexdocs.pm/routex/extensions/verified_routes.html\n"

    Logger.info([p1, p2])

    Keyword.merge(config, verified_sigil_routex: routex, verified_sigil_original: original)
  end

  require Phoenix.VerifiedRoutes

  defp uniform_path_matchspec(input) do
    Path.path_map(input)
  end

  @impl true
  def create_helpers(routes, _cm, _env) do
    # config = cm.config()

    # %{
    #   verified_sigil_routex: verified_sigil_routex,
    #   verified_sigil_original: verified_sigil_original
    # } = config

    # to_sigil_funname = fn "~" <> sigil_letter -> String.to_atom("sigil_" <> sigil_letter) end
    # org_sigil_fun_name = to_sigil_funname.(verified_sigil_original)
    # routex_sigil_fun_name = to_sigil_funname.(verified_sigil_routex)

    # pattern_routes =
    #   routes
    #   |> Route.group_by_method_and_origin()
    #   |> Enum.map(fn {{_method, path}, routes} ->
    #     pattern = uniform_path_matchspec(path)

    #     {pattern, routes}
    #   end)
    #   |> Map.new()

    # print a newline so the branch_macro's can safely print in their own
    # empty space
    IO.puts("")

    [
      branch_macro(routes, Phoenix.VerifiedRoutes, :sigil_p,
        as: :sigil_p,
        orig: :sigil_o,
        arg_pos: fn arity -> arity - 1 end
      ),
      branch_macro(routes, Phoenix.VerifiedRoutes, :url,
        as: :url,
        orig: :url_o,
        arg_pos: fn arity -> arity - 1 end
      ),
      branch_macro(routes, Phoenix.VerifiedRoutes, :path,
        as: :path,
        orig: :path_o,
        arg_pos: fn arity -> arity - 1 end
      )
    ]
  end

  def branch_macro(routes, module, fun, opts \\ [])
      when is_list(routes) and is_atom(module) and is_atom(fun) and is_list(opts) do
    as_fun = Keyword.get(opts, :as, fun)
    orig_fun = Keyword.get(opts, :orig, fun)
    arities = :macros |> module.__info__() |> Keyword.get_values(fun)

    ## Print a message to make developers aware of branched macro's.
    arities_str =
      if length(arities) == 1, do: "#{hd(arities)}", else: "{#{Enum.join(arities, ",")}}"

    mod_name = module |> Module.split() |> Enum.join(".")
    Utils.print("Generate branching variant of: #{mod_name}.#{fun}/#{arities_str}")

    for arity <- arities do
      # the value of option :arg_pos is at this point a function which defines
      # the argument (position) which should be branched. anonymous functions
      # can't enter the world of AST. That's why we evaluate :arg_pos at this
      # point and replace it with the resulting value.
      # Furthermore, we subtract 1 to make it a 0-based index value.
      args = Macro.generate_arguments(arity, __MODULE__)
      opts = Keyword.update(opts, :arg_pos, 0, &(&1.(arity) - 1))

      quote do
        require Routex.Extension.VerifiedRoutes

        defmacro unquote(orig_fun)(unquote_splicing(args)) do
          Routex.Extension.VerifiedRoutes.build_default(
            unquote(module),
            unquote(fun),
            unquote(args)
          )
        end

        # defmacro url(arg0, arg1, arg2)
        defmacro unquote(as_fun)(unquote_splicing(args)) do
          Routex.Extension.VerifiedRoutes.build_case(
            unquote(Macro.escape(routes)),
            __CALLER__,
            unquote(module),
            unquote(fun),
            unquote(args),
            unquote(opts)
          )
        end
      end
    end
  end

  def build_default(module, fun, args) do
    quote do
      unquote(module).unquote(fun)(unquote_splicing(args))
    end
  end

  # TODO: Are they all needed?
  defp fetch_segments(str) when is_binary(str), do: {:list, Path.split(str)}
  defp fetch_segments({:<<>>, _, segments}), do: {:list, segments}
  defp fetch_segments({:sigil_p, _, [{:<<>>, _, segments}, []]}), do: {:sigil, segments}

  def build_case(routes, caller, module, fun, args, opts) do
    helper_ast = Utils.get_helper_ast(caller)

    # defines which argument is branched.
    route_arg_pos = Keyword.get(opts, :arg_pos)
    route_arg = Enum.at(args, route_arg_pos)

    # we save the type of the argument and if necessary convert it to a list of segments
    # this way we can continue with a consistent format and restore the original format afterwards.
    {type, route_arg_segments} = fetch_segments(route_arg)

    matchable_arg_segments = Routex.Utils.matchable(route_arg_segments)

    # we could create a map upstream to be a bit more efficient but it makes
    # testing harder and not worth the microseconds.
    routes_matching_pattern =
      Enum.filter(routes, fn route ->
        matchable_path = route |> Attrs.get!(:__origin__) |> Routex.Utils.matchable()
        Routex.Utils.match?(matchable_path, matchable_arg_segments)
      end)

    clauses =
      for route <- routes_matching_pattern do
        orig_path = Attrs.get!(route, :__origin__)
        helper = Attrs.get!(route, :__order__) |> List.last()

        recomposed_route =
          route_arg_segments
          |> PathQueryFragment.recompose(orig_path, route.path)
          |> PathQueryFragment.join_statics()
          |> then(&{:<<>>, [], &1})

        recomposed_route_arg =
          case type do
            :sigil -> {:sigil_p, [], [recomposed_route, []]}
            :list -> recomposed_route
          end

        recomposed_args = List.replace_at(args, route_arg_pos, recomposed_route_arg)

        quote do
          unquote(helper) -> unquote(module).unquote(fun)(unquote_splicing(recomposed_args))
        end
      end
      |> List.flatten()
      |> Enum.uniq_by(& &1)

    if clauses == [] do
      Logger.critical("Failed to create branches for #{inspect(args)}")
      []
    else
      quote do
        case unquote(helper_ast) do
          unquote(clauses)
        end
      end
      |> Routex.ExtensionUtils.inspect_ast()
    end
  end
end
