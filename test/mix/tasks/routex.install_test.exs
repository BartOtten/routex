defmodule Mix.Tasks.Routex.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  test "installing routex" do
    [app_name: :routex]
    |> phx_test_project()
    |> Igniter.compose_task("routex.install", [])
    |> assert_has_patch("lib/routex_web/router.ex", """
      |    plug(:protect_from_forgery)
      |    plug(:put_secure_browser_headers)
    + |    plug :routex
      |  end
    """)
    |> assert_has_patch("lib/routex_web/router.ex", """
    + |  preprocess_using RoutexWeb.RoutexBackend do
    + |    scope "/", RoutexWeb do
    + |      pipe_through(:browser)
      |
    - |    get("/", PageController, :home)
    + |      get("/", PageController, :home)
    + |    end
      |  end
    """)
    |> assert_has_patch("lib/routex_web.ex", """
      | use Routex.Router
    """)
    |> assert_has_patch("lib/routex_web/router.ex", """
      | preprocess_using RoutexWeb.RoutexBackend do
    """)
    |> assert_creates("lib/routex_web/routex_backend.ex", """
    defmodule RoutexWeb.RoutexBackend do
      use Routex.Backend,
        extensions: [
          # required
          Routex.Extension.AttrGetters,

          # adviced
          Routex.Extension.LiveViewHooks,
          Routex.Extension.Plugs,
          Routex.Extension.VerifiedRoutes,
          Routex.Extension.Alternatives,
          Routex.Extension.AlternativeGetters,
          Routex.Extension.Assigns,
          Routex.Extension.Localize.Phoenix.Routes,
          Routex.Extension.Localize.Phoenix.Runtime,
          Routex.Extension.RuntimeDispatcher

          # optional
          # Routex.Extension.Translations,  # when you want translated routes
          # Routex.Extension.Interpolation, # when path prefixes don't cut it
          # Routex.Extension.RouteHelpers,  # when verified routes can't be used
          # Routex.Extension.Cldr,          # when combined with the Cldr ecosystem
        ],
        assigns: %{namespace: :rtx, attrs: [:locale, :language, :region]},
        verified_sigil_routex: "~p",
        verified_url_routex: :url,
        verified_path_routex: :path,
        dispatch_targets: [
          {Gettext, :put_locale, [[:attrs, :runtime, :language]]}
          # {Routex.Utils, :process_put_branch, [[:attrs, :__branch__]]}
        ]
    end
    """)
  end
end
