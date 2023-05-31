defmodule Routex.RouteTest do
  use ExUnit.Case, async: true

  alias Routex.Route

  test "get_nesting" do
    route = %Phoenix.Router.Route{private: %{routex: %{__order__: [0]}}}
    assert [] == Route.get_nesting(route)

    route = %Phoenix.Router.Route{private: %{routex: %{__order__: [0, 1]}}}
    assert [0] == Route.get_nesting(route)

    route = %Phoenix.Router.Route{private: %{routex: %{__order__: [0, 1]}}}
    assert [] == Route.get_nesting(route, -1)
  end

  test "group_by_nesting" do
    routes = [
      %Phoenix.Router.Route{path: "/", private: %{routex: %{__order__: [0, 0]}}},
      %Phoenix.Router.Route{path: "/page", private: %{routex: %{__order__: [0, 1, 0]}}},
      %Phoenix.Router.Route{
        path: "/page/edit",
        private: %{routex: %{__order__: [0, 2, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt1",
        private: %{routex: %{__order__: [0, 1, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt2",
        private: %{routex: %{__order__: [0, 1, 2]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit_alt1",
        private: %{routex: %{__order__: [0, 2, 1]}}
      }
    ]

    expected = %{
      [0] => [%Phoenix.Router.Route{path: "/", private: %{routex: %{__order__: [0, 0]}}}],
      [0, 1] => [
        %Phoenix.Router.Route{path: "/page", private: %{routex: %{__order__: [0, 1, 0]}}},
        %Phoenix.Router.Route{
          path: "/page_alt1",
          private: %{routex: %{__order__: [0, 1, 1]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt2",
          private: %{routex: %{__order__: [0, 1, 2]}}
        }
      ],
      [0, 2] => [
        %Phoenix.Router.Route{
          path: "/page/edit",
          private: %{routex: %{__order__: [0, 2, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page/edit_alt1",
          private: %{routex: %{__order__: [0, 2, 1]}}
        }
      ]
    }

    assert expected == Route.group_by_nesting(routes)
  end

  test "group_by_method_and_path" do
    routes = [
      %Phoenix.Router.Route{path: "/", verb: :get, private: %{routex: %{__order__: [0, 0]}}},
      %Phoenix.Router.Route{
        path: "/page",
        verb: :get,
        private: %{routex: %{__order__: [0, 1, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit",
        verb: :get,
        private: %{routex: %{__order__: [0, 2, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt1",
        verb: :get,
        private: %{routex: %{__order__: [0, 1, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt2",
        verb: :get,
        private: %{routex: %{__order__: [0, 1, 2]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit_alt1",
        verb: :get,
        private: %{routex: %{__order__: [0, 2, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page",
        verb: :post,
        private: %{routex: %{__order__: [0, 3, 0]}}
      }
    ]

    expected = %{
      {:get, "/"} => [
        %Phoenix.Router.Route{path: "/", verb: :get, private: %{routex: %{__order__: [0, 0]}}}
      ],
      {:get, "/page"} => [
        %Phoenix.Router.Route{
          path: "/page",
          verb: :get,
          private: %{routex: %{__order__: [0, 1, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt1",
          verb: :get,
          private: %{routex: %{__order__: [0, 1, 1]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt2",
          verb: :get,
          private: %{routex: %{__order__: [0, 1, 2]}}
        }
      ],
      {:get, "/page/edit"} => [
        %Phoenix.Router.Route{
          path: "/page/edit",
          verb: :get,
          private: %{routex: %{__order__: [0, 2, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page/edit_alt1",
          verb: :get,
          private: %{routex: %{__order__: [0, 2, 1]}}
        }
      ],
      {:post, "/page"} => [
        %Phoenix.Router.Route{
          path: "/page",
          verb: :post,
          private: %{routex: %{__order__: [0, 3, 0]}}
        }
      ]
    }

    assert expected == Route.group_by_method_and_path(routes)
  end
end
