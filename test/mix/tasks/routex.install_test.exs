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
        extensions: [Routex.Extension.AttrGetters]
    end
    """)
  end
end
