defmodule Routex.Extension.VerifiedRoutes do
  @moduledoc ~S"""
  Provides route generation with compile-time verification.

  Provides a sigil (default: ~l) with the ability to verify routes even when
  the route has been transformed by Routex extensions. This allows the
  use of the original route paths in controllers and templates.

  The sigil to use can be set to ~p  to override Phoenix' default as it is
  a drop-in replacement.

  ## Options
  - `verified_sigil_routex`: Sigil to use for Routex verified routes (default: "~l")
  - `verified_sigil_original`: Sigil for original routes when `verified_sigil_routex` is set to "~p". (default: "~o")

  When setting `verified_sigil_routex` option to "~p" an additional changes must be made.

  ```diff
  # file /lib/example_web.ex
  defp routex_helpers do
  + import Phoenix.VerifiedRoutes, except: [sigil_p: 2]
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
      # in (h)eex template

      # for a 1-on-1 mapping
      ~l"/products/#{product}"   ⇒  ~p"/transformed/products/#{product}"

      # or when alternative routes are created
      ~l"/products/#{product}"  ⇒ case alternative do
                                     nil ⇒  ~p"/products/#{product}"
                                    "en" ⇒  ~p"/products/#{product}"
                                    "eu_nl" ⇒  ~p"/europe/nl/products/#{product}"
                                    "eu_be" ⇒  ~p"/europe/be/products/#{product}"
                                  end

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.ExtensionUtils
  alias Routex.Path
  alias Routex.Route
  require Logger

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

    pattern_routes =
      routes
      |> Route.group_by_method_and_path()
      |> Enum.map(fn {{_method, path}, routes} ->
        {Path.to_match_pattern(path), routes}
      end)
      |> Map.new()

    to_sigil_funname = fn "~" <> sigil_letter -> String.to_atom("sigil_" <> sigil_letter) end
    org_sigil_fun_name = to_sigil_funname.(verified_sigil_original)
    routex_sigil_fun_name = to_sigil_funname.(verified_sigil_routex)
    phoenix_sigil_fun_name = to_sigil_funname.(@phoenix_sigil)

    original_sigil_ast =
      if verified_sigil_routex == @phoenix_sigil do
        quote location: :keep do
          defmacro unquote(org_sigil_fun_name)(route, flags) do
            quote location: :keep do
              Phoenix.VerifiedRoutes.sigil_p(unquote(route), unquote(flags))
            end
          end
        end
      end

    routex_sigil_ast =
      quote location: :keep do
        defmacro unquote(routex_sigil_fun_name)(route, flags) do
          callback =
            fn reroute ->
              quote location: :keep do
                Phoenix.VerifiedRoutes.sigil_p(unquote(reroute), unquote(flags))
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
      quote location: :keep do
        defmacro url({unquote(org_sigil_fun_name), meta, opts}) do
          quote location: :keep, do: Phoenix.VerifiedRoutes.url(unquote({:sigil_p, meta, opts}))
        end

        defmacro url(conn_or_endpoint, {unquote(org_sigil_fun_name), meta, opts}) do
          quote location: :keep,
                do: Phoenix.VerifiedRoutes.url(unquote(conn_or_endpoint, {:sigil_p, meta, opts}))
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
      quote location: :keep do
        defmacro path(conn_or_endpoint, router, {unquote(org_sigil_fun_name), meta, opts}) do
          quote location: :keep,
                do:
                  Phoenix.VerifiedRoutes.path(
                    unquote(conn_or_endpoint, router, {:sigil_p, meta, opts})
                  )
        end

        defmacro path(conn_or_endpoint, {unquote(org_sigil_fun_name), meta, opts}) do
          quote location: :keep,
                do: Phoenix.VerifiedRoutes.url(unquote(conn_or_endpoint, {:sigil_p, meta, opts}))
        end
      end

    # branching url/[2,3,4]
    branching_url_ast =
      quote location: :keep do
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
          callback = fn reroute ->
            quote location: :keep do
              Phoenix.VerifiedRoutes.url(
                unquote(endpoint),
                unquote(router),
                sigil_p(unquote(reroute), unquote(rest))
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
      quote location: :keep do
        defmacro path(endpoint, route) do
          router = attr!(__CALLER__, :router)
          quote do: path(unquote(endpoint), unquote(router), unquote(route))
        end

        defmacro path(
                   endpoint,
                   router,
                   {unquote(routex_sigil_fun_name), meta, [route | rest] = opts}
                 ) do
          callback = fn reroute ->
            quote location: :keep do
              Phoenix.VerifiedRoutes.path(
                unquote(endpoint),
                unquote(router),
                sigil_p(unquote(reroute), unquote(rest))
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

    url_catchall_ast =
      quote do
        defmacro url(other), do: raise_invalid_route(other)

        defmacro url(_conn_or_socket_or_endpoint_or_uri, other),
          do: raise_invalid_route(other)

        defmacro url(_conn_or_socket_or_endpoint_or_uri, _router, other),
          do: raise_invalid_route(other)
      end

    path_catchall_ast =
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
                "expected compile-time ~l path string, got: #{Macro.to_string(ast)}\n" <>
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
      url_catchall_ast,
      original_path_ast,
      branching_path_ast,
      path_catchall_ast,
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
      quote do
        unquote(callback.(route))
      end
    else
      clauses = build_branches(segments, routes_matching_pattern, callback)
      build_tree(segments, clauses, caller)
    end
  end

  defp build_tree(segments, clauses, caller) do
    helper_ast = ExtensionUtils.get_helper_ast(caller)

    quote do
      case {unquote(Macro.escape(segments)), unquote(helper_ast)} do
        unquote(clauses)
      end
    end
  end

  defp build_branches(segments, routes_matching_pattern, callback) do
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
