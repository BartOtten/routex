defmodule Routex.RouteTest do
  use ExUnit.Case, async: true

  alias Routex.Route

  test "get_nesting" do
    route = %Phoenix.Router.Route{private: %{routex: %{__branch__: [0]}}}
    assert [] == Route.get_nesting(route)

    route = %Phoenix.Router.Route{private: %{routex: %{__branch__: [0, 1]}}}
    assert [0] == Route.get_nesting(route)

    route = %Phoenix.Router.Route{private: %{routex: %{__branch__: [0, 1]}}}
    assert [] == Route.get_nesting(route, -1)
  end

  test "group_by_nesting within a branch" do
    routes = [
      %Phoenix.Router.Route{
        path: "/",
        private: %{routex: %{__branch__: [0, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page",
        private: %{routex: %{__branch__: [0, 1, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit",
        private: %{routex: %{__branch__: [0, 2, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt1",
        private: %{routex: %{__branch__: [0, 1, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt2",
        private: %{routex: %{__branch__: [0, 1, 2]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit_alt1",
        private: %{routex: %{__branch__: [0, 2, 1]}}
      }
    ]

    expected = %{
      [0] => [
        %Phoenix.Router.Route{
          path: "/",
          private: %{routex: %{__branch__: [0, 0]}}
        }
      ],
      [0, 1] => [
        %Phoenix.Router.Route{
          path: "/page",
          private: %{routex: %{__branch__: [0, 1, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt1",
          private: %{routex: %{__branch__: [0, 1, 1]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt2",
          private: %{routex: %{__branch__: [0, 1, 2]}}
        }
      ],
      [0, 2] => [
        %Phoenix.Router.Route{
          path: "/page/edit",
          private: %{routex: %{__branch__: [0, 2, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page/edit_alt1",
          private: %{routex: %{__branch__: [0, 2, 1]}}
        }
      ]
    }

    assert expected == Route.group_by_nesting(routes)
  end

  test "group_by_nesting without a branch" do
    routes = [
      %Phoenix.Router.Route{
        path: "/page",
        private: %{routex: %{__branch__: [0, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit",
        private: %{routex: %{__branch__: [1, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt1",
        private: %{routex: %{__branch__: [0, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt2",
        private: %{routex: %{__branch__: [0, 2]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit_alt1",
        private: %{routex: %{__branch__: [1, 1]}}
      }
    ]

    expected = %{
      [0] => [
        %Phoenix.Router.Route{path: "/page", private: %{routex: %{__branch__: [0, 0]}}},
        %Phoenix.Router.Route{
          path: "/page_alt1",
          private: %{routex: %{__branch__: [0, 1]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt2",
          private: %{routex: %{__branch__: [0, 2]}}
        }
      ],
      [1] => [
        %Phoenix.Router.Route{
          path: "/page/edit",
          private: %{routex: %{__branch__: [1, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page/edit_alt1",
          private: %{routex: %{__branch__: [1, 1]}}
        }
      ]
    }

    assert expected == Route.group_by_nesting(routes)
  end

  test "group_by_method_and_path in a branch" do
    routes = [
      %Phoenix.Router.Route{
        path: "/",
        verb: :get,
        private: %{routex: %{__branch__: [0, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page",
        verb: :get,
        private: %{routex: %{__branch__: [0, 1, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit",
        verb: :get,
        private: %{routex: %{__branch__: [0, 2, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt1",
        verb: :get,
        private: %{routex: %{__branch__: [0, 1, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt2",
        verb: :get,
        private: %{routex: %{__branch__: [0, 1, 2]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit_alt1",
        verb: :get,
        private: %{routex: %{__branch__: [0, 2, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page",
        verb: :post,
        private: %{routex: %{__branch__: [0, 3, 0]}}
      }
    ]

    expected = %{
      {:get, "/"} => [
        %Phoenix.Router.Route{
          path: "/",
          verb: :get,
          private: %{routex: %{__branch__: [0, 0]}}
        }
      ],
      {:get, "/page"} => [
        %Phoenix.Router.Route{
          path: "/page",
          verb: :get,
          private: %{routex: %{__branch__: [0, 1, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt1",
          verb: :get,
          private: %{routex: %{__branch__: [0, 1, 1]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt2",
          verb: :get,
          private: %{routex: %{__branch__: [0, 1, 2]}}
        }
      ],
      {:get, "/page/edit"} => [
        %Phoenix.Router.Route{
          path: "/page/edit",
          verb: :get,
          private: %{routex: %{__branch__: [0, 2, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page/edit_alt1",
          verb: :get,
          private: %{routex: %{__branch__: [0, 2, 1]}}
        }
      ],
      {:post, "/page"} => [
        %Phoenix.Router.Route{
          path: "/page",
          verb: :post,
          private: %{routex: %{__branch__: [0, 3, 0]}}
        }
      ]
    }

    assert expected == Route.group_by_method_and_path(routes)
  end

  test "group_by_method_and_path outside a branch" do
    routes = [
      %Phoenix.Router.Route{
        path: "/page",
        verb: :get,
        private: %{routex: %{__branch__: [1, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit",
        verb: :get,
        private: %{routex: %{__branch__: [2, 0]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt1",
        verb: :get,
        private: %{routex: %{__branch__: [1, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt2",
        verb: :get,
        private: %{routex: %{__branch__: [1, 2]}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit_alt1",
        verb: :get,
        private: %{routex: %{__branch__: [2, 1]}}
      },
      %Phoenix.Router.Route{
        path: "/page",
        verb: :post,
        private: %{routex: %{__branch__: [3, 0]}}
      }
    ]

    expected = %{
      {:get, "/page"} => [
        %Phoenix.Router.Route{
          path: "/page",
          verb: :get,
          private: %{routex: %{__branch__: [1, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt1",
          verb: :get,
          private: %{routex: %{__branch__: [1, 1]}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt2",
          verb: :get,
          private: %{routex: %{__branch__: [1, 2]}}
        }
      ],
      {:get, "/page/edit"} => [
        %Phoenix.Router.Route{
          path: "/page/edit",
          verb: :get,
          private: %{routex: %{__branch__: [2, 0]}}
        },
        %Phoenix.Router.Route{
          path: "/page/edit_alt1",
          verb: :get,
          private: %{routex: %{__branch__: [2, 1]}}
        }
      ],
      {:post, "/page"} => [
        %Phoenix.Router.Route{
          path: "/page",
          verb: :post,
          private: %{routex: %{__branch__: [3, 0]}}
        }
      ]
    }

    assert expected == Route.group_by_method_and_path(routes)
  end

  test "group_by_method_and_origin outside a branch" do
    routes = [
      %Phoenix.Router.Route{
        path: "/page",
        verb: :get,
        private: %{routex: %{__branch__: [1, 0], __origin__: "/page"}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit",
        verb: :get,
        private: %{routex: %{__branch__: [2, 0], __origin__: "/page/edit"}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt1",
        verb: :get,
        private: %{routex: %{__branch__: [1, 1], __origin__: "/page"}}
      },
      %Phoenix.Router.Route{
        path: "/page_alt2",
        verb: :get,
        private: %{routex: %{__branch__: [1, 2], __origin__: "/page"}}
      },
      %Phoenix.Router.Route{
        path: "/page/edit_alt1",
        verb: :get,
        private: %{routex: %{__branch__: [2, 1], __origin__: "/page/edit"}}
      },
      %Phoenix.Router.Route{
        path: "/page",
        verb: :post,
        private: %{routex: %{__branch__: [3, 0], __origin__: "/page"}}
      }
    ]

    expected = %{
      {:get, "/page"} => [
        %Phoenix.Router.Route{
          path: "/page",
          verb: :get,
          private: %{routex: %{__branch__: [1, 0], __origin__: "/page"}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt1",
          verb: :get,
          private: %{routex: %{__branch__: [1, 1], __origin__: "/page"}}
        },
        %Phoenix.Router.Route{
          path: "/page_alt2",
          verb: :get,
          private: %{routex: %{__branch__: [1, 2], __origin__: "/page"}}
        }
      ],
      {:get, "/page/edit"} => [
        %Phoenix.Router.Route{
          path: "/page/edit",
          verb: :get,
          private: %{routex: %{__branch__: [2, 0], __origin__: "/page/edit"}}
        },
        %Phoenix.Router.Route{
          path: "/page/edit_alt1",
          verb: :get,
          private: %{routex: %{__branch__: [2, 1], __origin__: "/page/edit"}}
        }
      ],
      {:post, "/page"} => [
        %Phoenix.Router.Route{
          path: "/page",
          verb: :post,
          private: %{routex: %{__branch__: [3, 0], __origin__: "/page"}}
        }
      ]
    }

    assert expected == Route.group_by_method_and_origin(routes)
  end
end

defmodule Routex.RouteTest_ModuleMocking do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn -> Code.require_file("deps/phoenix/lib/phoenix/router/route.ex") end)
  end

  describe "exprs/2 fallback branch" do
    test "calls exprs/1 when exprs/2 is not available" do
      Code.compiler_options(ignore_module_conflict: true)
      # Define a fake Phoenix.Router.Route that only exports exprs/1.
      Code.compile_string("""
      defmodule Phoenix.Router.Route do
        def exprs(one), do: {:one, one}
      end
      """)

      env = %{module: __MODULE__}
      route = :test_route

      assert Routex.Route.exprs(route, env) == {:one, route}

      Code.require_file("deps/phoenix/lib/phoenix/router/route.ex")
    end

    test "calls exprs/2 when exprs/2 is available" do
      Code.compiler_options(ignore_module_conflict: true)
      # Define a fake Phoenix.Router.Route that only exports exprs/1.
      Code.compile_string("""
      defmodule Phoenix.Router.Route do
        def exprs(route, _forwards), do: {:two, route}
      end
      """)

      env = %{module: __MODULE__}
      route = :test_route

      # With no exprs/2 available, the fallback branch is taken.
      assert Routex.Route.exprs(route, env) == {:two, :test_route}

      Code.require_file("deps/phoenix/lib/phoenix/router/route.ex")
    end
  end
end
