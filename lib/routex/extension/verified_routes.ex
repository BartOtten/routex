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
    import ExampleWeb.Router.RoutexHelpers
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

  @impl Routex.Extension
  def create_helpers(routes, cm, _env) do
    config = cm.config()

    %{
      verified_sigil_routex: verified_sigil_routex,
      verified_sigil_original: verified_sigil_original
    } = config

    to_sigil_funname = fn "~" <> sigil_letter -> String.to_atom("sigil_" <> sigil_letter) end
    org_sigil_fun_name = to_sigil_funname.(verified_sigil_original)
    routex_sigil_fun_name = to_sigil_funname.(verified_sigil_routex)

    pattern_routes =
      routes
      |> Route.group_by_method_and_path()
      |> Enum.map(fn {{_method, path}, routes} ->
        {Path.to_match_pattern(path), routes}
      end)
      |> Map.new()

    original_sigil_ast =
      if verified_sigil_routex == @phoenix_sigil do
        quote do
          defmacro unquote(org_sigil_fun_name)(route, flags) do
            quote do
              Phoenix.VerifiedRoutes.sigil_p(unquote(route), unquote(flags))
            end
          end
        end
      end

    routex_sigil_ast =
      quote do
        defmacro unquote(routex_sigil_fun_name)(route, flags) do
          callback =
            fn route ->
              quote do
                Phoenix.VerifiedRoutes.sigil_p(unquote(route), unquote(flags))
              end
            end

          Routex.Extension.VerifiedRoutes.branch_callback(
            route,
            unquote(Macro.escape(pattern_routes)),
            __CALLER__,
            callback
          )
        end
      end

    # create drop-in variants of Phoenix.VerifiedRoutes.url/{1,2,3} for custom 'original' sigil
    original_url_ast =
      quote do
        defmacro url({unquote(org_sigil_fun_name), meta, opts}) do
          quote do: Phoenix.VerifiedRoutes.url(unquote({:sigil_p, meta, opts}))
        end

        defmacro url(conn_or_endpoint, {unquote(org_sigil_fun_name), meta, opts}) do
          quote do: Phoenix.VerifiedRoutes.url(unquote(conn_or_endpoint, {:sigil_p, meta, opts}))
        end

        defmacro url(conn_or_endpoint, router, {unquote(org_sigil_fun_name), meta, opts}) do
          quote location: :keep,
                do:
                  Phoenix.VerifiedRoutes.url(
                    unquote(conn_or_endpoint, router, {:sigil_p, meta, opts})
                  )
        end
      end

    # create drop-in variants of Phoenix.VerifiedRoutes.path/{2,3} for custom 'original' sigil
    original_path_ast =
      quote do
        defmacro path(conn_or_endpoint, router, {unquote(org_sigil_fun_name), meta, opts}) do
          quote location: :keep,
                do:
                  Phoenix.VerifiedRoutes.path(
                    unquote(conn_or_endpoint, router, {:sigil_p, meta, opts})
                  )
        end

        defmacro path(conn_or_endpoint, {unquote(org_sigil_fun_name), meta, opts}) do
          quote do: Phoenix.VerifiedRoutes.url(unquote(conn_or_endpoint, {:sigil_p, meta, opts}))
        end
      end

    # branching url/[2,3,4]
    branching_url_ast =
      quote do
        defmacro url(route) do
          router = router = attr!(__CALLER__, :router)
          endpoint = attr!(__CALLER__, :endpoint)
          quote do: url(unquote(endpoint), unquote(router), unquote(route))
        end

        defmacro url(endpoint, route) do
          router = attr!(__CALLER__, :router)
          quote do: url(unquote(endpoint), unquote(router), unquote(route))
        end

        defmacro url(
                   endpoint,
                   router,
                   {unquote(routex_sigil_fun_name), meta, [route | rest] = opts}
                 ) do
          callback = fn route ->
            quote do
              Phoenix.VerifiedRoutes.url(
                unquote(endpoint),
                unquote(router),
                unquote({:sigil_p, meta, [route | rest]})
              )
            end
          end

          Routex.Extension.VerifiedRoutes.branch_callback(
            route,
            unquote(Macro.escape(pattern_routes)),
            __CALLER__,
            callback
          )
        end
      end

    # branching path/[2,3]
    branching_path_ast =
      quote do
        defmacro path(endpoint, route) do
          router = attr!(__CALLER__, :router)
          quote do: path(unquote(endpoint), unquote(router), unquote(route))
        end

        defmacro path(
                   endpoint,
                   router,
                   {unquote(routex_sigil_fun_name), meta, [route | rest] = opts}
                 ) do
          callback = fn route ->
            quote do
              Phoenix.VerifiedRoutes.path(
                unquote(endpoint),
                unquote(router),
                unquote({:sigil_p, meta, [route | rest]})
              )
            end
          end

          Routex.Extension.VerifiedRoutes.branch_callback(
            route,
            unquote(Macro.escape(pattern_routes)),
            __CALLER__,
            callback
          )
        end
      end

    catchall_url_ast =
      quote do
        defmacro url(other), do: raise_invalid_route(other)

        defmacro url(_conn_or_socket_or_endpoint_or_uri, other),
          do: raise_invalid_route(other)

        defmacro url(_conn_or_socket_or_endpoint_or_uri, _router, other),
          do: raise_invalid_route(other)
      end

    catchall_path_ast =
      quote do
        defmacro path(_conn_or_socket_or_endpoint_or_uri, other),
          do: raise_invalid_route(other)

        defmacro path(_conn_or_socket_or_endpoint_or_uri, _router, other),
          do: raise_invalid_route(other)
      end

    phoenix_clones_ast =
      quote do
        # Clones of private functions in Phoenix.VerifiedRoutes

        defp raise_invalid_route(ast) do
          raise ArgumentError,
                "expected compile-time #{unquote(verified_sigil_routex)} path string, got: #{Macro.to_string(ast)}\n" <>
                  "Use unverified_path/2 and unverified_url/2 if you need to build an arbitrary path."
        end

        # unused; kept for clearity
        # defp attr!(%{function: nil}, _) do
        #   raise "Phoenix.VerifiedRoutes can only be used inside functions, please move your usage of ~p to functions"
        # end

        defp attr!(env, :endpoint) do
          Module.get_attribute(env.module, :endpoint) ||
            raise """
            expected @endpoint to be set. For dynamic endpoint resolution, use path/2 instead.

            for example:

                path(conn_or_socket, ~p"/my-path")
            """
        end

        defp attr!(env, name) do
          Module.get_attribute(env.module, name) ||
            raise "expected @#{name} module attribute to be set"
        end
      end

    [
      original_sigil_ast,
      routex_sigil_ast,
      original_url_ast,
      branching_url_ast,
      catchall_url_ast,
      original_path_ast,
      branching_path_ast,
      catchall_path_ast,
      phoenix_clones_ast
    ]
  end

  @doc false
  def branch_callback(route, pattern_routes, caller, callback) do
    {:<<>>, _meta, segments} = route
    pattern = Path.to_match_pattern(segments)
    routes_matching_pattern = Map.get(pattern_routes, pattern, [])

    # Routex does not handle all routes. Use the fallback if we find
    # none handled by Routex.
    if routes_matching_pattern === [] do
      # TODO: Do warn when no route matches; see disabled tests

      quote do
        unquote(callback.(route))
      end
    else
      clauses = build_case_clauses(segments, routes_matching_pattern, callback)
      build_case(segments, clauses, caller)
    end
  end

  defp build_case(segments, clauses, caller) do
    helper_ast = ExtensionUtils.get_helper_ast(caller)

    quote do
      case {unquote(Macro.escape(segments)), unquote(helper_ast)} do
        unquote(clauses)
      end
    end
  end

  defp build_case_clauses(segments, routes_matching_pattern, callback) do
    for route <- routes_matching_pattern do
      new_segments = route |> Attrs.get(:__origin__) |> Path.recompose(route.path, segments)
      helper = route |> Attrs.get(:__order__) |> List.last()

      quote do
        {unquote(Macro.escape(segments)), unquote(helper)} ->
          unquote(callback.(quote do: <<unquote_splicing(new_segments)>>))
      end
    end
    |> List.flatten()
    |> Enum.uniq()
  end
end
