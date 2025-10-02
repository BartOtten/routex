defmodule Routex.Extension.AlternativesTest do
  use ExUnit.Case, async: true

  alias Routex.Extension.Alternatives
  import Routex.Test.Fixtures

  defmodule Conf1 do
    use(Routex.Backend,
      extensions: [Routex.Extension.Alternatives],
      alternatives: branches()
    )
  end

  test "configure adds precomputed values" do
    config = [alternatives: branches()]
    result = Alternatives.configure(config, :backend)

    assert match?(
             [
               {:branches,
                %{
                  nil => %{},
                  "foo" => %{},
                  "foo_nested" => %Routex.Extension.Alternatives.Branch.Flat{
                    attrs: %{
                      custom_key: :n1,
                      language: "en",
                      opt_attr: "default"
                    }
                  },
                  "foo_nested_nested2" => %{}
                }}
               | [
                   alternatives: %{
                     "/" => %{
                       branches: %{
                         "/foo" => %{
                           branches: %{
                             "/nested" => %{
                               branches: %{
                                 "/nested2" => %{
                                   attrs: %{}
                                 }
                               },
                               attrs: %{}
                             }
                           },
                           attrs: %{}
                         }
                       },
                       attrs: %{}
                     }
                   }
                 ]
             ],
             result
           )
  end

  test "generates new routes" do
    routes = [
      %Phoenix.Router.Route{path: "/", verb: :get, private: %{routex: %{__branch__: [0]}}},
      %Phoenix.Router.Route{
        path: "/products/:id",
        verb: :get,
        private: %{routex: %{__branch__: [1]}}
      },
      %Phoenix.Router.Route{
        path: "/posts/:id",
        verb: :get,
        private: %{routex: %{alternatives_prefix: false, __branch__: [2]}}
      }
    ]

    expected = [
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [0, 0],
            branch_key: nil,
            branch_path: [],
            branch_prefix: "/",
            language: "en",
            opt_attr: "default",
            custom_key: :root
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/foo",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [0, 1],
            branch_key: "foo",
            branch_path: ["foo"],
            branch_prefix: "/foo",
            language: "en",
            opt_attr: "default",
            custom_key: :root
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/foo/nested",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [0, 2],
            branch_key: "foo_nested",
            branch_path: ["foo", "nested"],
            branch_prefix: "/foo/nested",
            language: "en",
            opt_attr: "default",
            custom_key: :n1
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/foo/nested/nested2",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [0, 3],
            branch_key: "foo_nested_nested2",
            branch_path: ["foo", "nested", "nested2"],
            branch_prefix: "/foo/nested/nested2",
            language: "en",
            opt_attr: "default",
            custom_key: :n2
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/products/:id",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [1, 0],
            branch_key: nil,
            branch_path: [],
            branch_prefix: "/",
            language: "en",
            opt_attr: "default",
            custom_key: :root
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/foo/products/:id",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [1, 1],
            branch_key: "foo",
            branch_path: ["foo"],
            branch_prefix: "/foo",
            language: "en",
            opt_attr: "default",
            custom_key: :root
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/foo/nested/products/:id",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [1, 2],
            branch_key: "foo_nested",
            branch_path: ["foo", "nested"],
            branch_prefix: "/foo/nested",
            language: "en",
            opt_attr: "default",
            custom_key: :n1
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/foo/nested/nested2/products/:id",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [1, 3],
            branch_key: "foo_nested_nested2",
            branch_path: ["foo", "nested", "nested2"],
            branch_prefix: "/foo/nested/nested2",
            language: "en",
            opt_attr: "default",
            custom_key: :n2
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/posts/:id",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [2, 0],
            alternatives_prefix: false,
            branch_path: [],
            branch_prefix: "/",
            custom_key: :root,
            language: "en",
            opt_attr: "default",
            branch_key: nil
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/posts/:id",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [2, 1],
            alternatives_prefix: false,
            branch_path: ["foo"],
            branch_prefix: "/foo",
            custom_key: :root,
            language: "en",
            opt_attr: "default",
            branch_key: "foo"
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/posts/:id",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [2, 2],
            alternatives_prefix: false,
            branch_path: ["foo", "nested"],
            branch_prefix: "/foo/nested",
            custom_key: :n1,
            language: "en",
            opt_attr: "default",
            branch_key: "foo_nested"
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Phoenix.Router.Route{
        assigns: nil,
        helper: nil,
        hosts: nil,
        kind: nil,
        line: nil,
        metadata: nil,
        path: "/posts/:id",
        pipe_through: nil,
        plug: nil,
        plug_opts: nil,
        private: %{
          routex: %{
            __branch__: [2, 3],
            alternatives_prefix: false,
            branch_path: ["foo", "nested", "nested2"],
            branch_prefix: "/foo/nested/nested2",
            custom_key: :n2,
            language: "en",
            opt_attr: "default",
            branch_key: "foo_nested_nested2"
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      }
    ]

    assert expected == Alternatives.transform(routes, Conf1, __ENV__)
  end
end
