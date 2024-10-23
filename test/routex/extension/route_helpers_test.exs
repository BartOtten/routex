defmodule Routex.Extension.RouteHelpersTest do
  use ExUnit.Case

  alias Routex.Extension.RouteHelpers

  test "creates helper functions" do
    routes = [
      %Phoenix.Router.Route{
        helper: "home",
        path: "/",
        verb: :get,
        private: %{routex: %{__origin__: "/", __branch__: [0, 0]}}
      },
      %Phoenix.Router.Route{
        helper: "home_alt1",
        path: "/alt1",
        verb: :get,
        private: %{routex: %{__origin__: "/", __branch__: [0, 0, 1]}}
      },
      %Phoenix.Router.Route{
        helper: "home_alt2",
        path: "/alt2",
        verb: :get,
        private: %{routex: %{__origin__: "/", __branch__: [0, 0, 2]}}
      },
      %Phoenix.Router.Route{
        helper: "products",
        path: "/products/:id",
        verb: :get,
        private: %{routex: %{__origin__: "/products/:id", __branch__: [0, 1]}}
      },
      %Phoenix.Router.Route{
        helper: "posts",
        path: "/posts/:id",
        verb: :get,
        private: %{routex: %{__origin__: "/posts/:id", __branch__: [0, 2]}}
      }
    ]

    ast = RouteHelpers.create_helpers(routes, nil, __ENV__)

    {:module, module, _, _} = Module.create(HelpersModule, ast, __ENV__)

    expected =
      [
        home_alt1_path: 2,
        home_alt1_path: 3,
        home_alt1_url: 2,
        home_alt1_url: 3,
        home_alt2_path: 2,
        home_alt2_path: 3,
        home_alt2_url: 2,
        home_alt2_url: 3,
        static_path: 2
      ]

    assert expected == module.__info__(:functions)
  end
end
