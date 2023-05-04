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

  use Routex.Extension
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
      |> Route.group_by_path()
      |> Enum.map(fn {path, routes} -> {Path.build_path_match(path), routes} end)
      |> Map.new()

    original_sigil =
      if verified_sigil_routex == @phoenix_sigil do
        "~" <> sigil_letter = verified_sigil_original
        sigil_fun_name = String.to_atom("sigil_" <> sigil_letter)

        quote location: :keep do
          defmacro unquote(sigil_fun_name)({:<<>>, meta, segments} = route, extra) do
            quote location: :keep do
              Phoenix.VerifiedRoutes.sigil_p(unquote(route), unquote(extra))
            end
          end
        end
      end

    localized_sigil =
      quote location: :keep do
        defmacro sigil_p(route, extra) do
          Routex.Extension.VerifiedRoutes.sigil_callback(
            route,
            extra,
            unquote(Macro.escape(pattern_routes)),
            __CALLER__
          )
        end
      end

    [original_sigil, localized_sigil]
  end

  @doc false
  def sigil_callback(route, extra, pattern_routes, caller) do
    {:<<>>, _meta, segments} = route
    pattern = Path.build_path_match(segments)
    routes_matching_pattern = Map.get(pattern_routes, pattern, [])

    # Routex does not handle all routes. Return the original route if we find
    # none handled by Routex.
    if routes_matching_pattern === [] do
      quote do
        Phoenix.VerifiedRoutes.sigil_p(unquote(route), unquote(extra))
      end
    else
      build_case(segments, routes_matching_pattern, caller)
    end
  end

  defp build_case(segments, routes_matching_pattern, caller) do
    cases = build_case_clauses(segments, routes_matching_pattern)
    helper_ast = ExtensionUtils.get_helper_ast(caller)

    quote do
      case {unquote(Macro.escape(segments)), unquote(helper_ast)} do
        unquote(cases)
      end
    end
  end

  defp build_case_clauses(segments, routes_matching_pattern) do
    for route <- routes_matching_pattern do
      new_segments = route |> Attrs.get(:__origin__) |> Path.recompose(route.path, segments)

      helper = route |> Attrs.get(:__order__) |> List.last()

      quote do
        {unquote(Macro.escape(segments)), unquote(helper)} ->
          Phoenix.VerifiedRoutes.sigil_p(<<unquote_splicing(new_segments)>>, [])
      end
    end
    |> List.flatten()
    |> Enum.uniq()
  end
end
