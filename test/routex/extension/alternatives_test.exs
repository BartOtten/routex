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
    config = %{alternatives: branches()}
    result = Alternatives.configure(config, :backend)

    assert match?(
             [
               {:branches,
                %{
                  nil => %{},
                  "foo" => %{},
                  "foo_nested" => %Routex.Extension.Alternatives.Branch.Flat{
                    attrs: %{
                      key: :n1,
                      language: "en",
                      opt_attr: "default",
                      branch_helper: "foo_nested"
                    }
                  },
                  "foo_nested_nested2" => %{}
                }}
               | %{
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
                 }
             ],
             result
           )
  end

  test "generates new routes" do
    routes = [
      %Routex.Route{path: "/", verb: :get, private: %{routex: %{__branch__: [0]}}},
      %Routex.Route{
        path: "/products/:id",
        verb: :get,
        private: %{routex: %{__branch__: [1]}}
      },
      %Routex.Route{
        path: "/posts/:id",
        verb: :get,
        private: %{routex: %{alternatives_prefix: false, __branch__: [2]}}
      }
    ]

    expected = [
      %Routex.Route{
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
            key: :root,
            language: "en",
            opt_attr: "default",
            branch_helper: nil,
            __branch__: [0, 0],
            branch_alias: nil,
            branch_path: [],
            branch_prefix: "/"
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Routex.Route{
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
            key: :root,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo",
            __branch__: [0, 1],
            branch_alias: :foo,
            branch_path: ["foo"],
            branch_prefix: "/foo"
          }
        },
        trailing_slash?: nil,
        verb: :get,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/foo/nested",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :n1,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo_nested",
            __branch__: [0, 2],
            branch_alias: :foo_nested,
            branch_path: ["foo", "nested"],
            branch_prefix: "/foo/nested"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/foo/nested/nested2",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :n2,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo_nested_nested2",
            __branch__: [0, 3],
            branch_alias: :foo_nested_nested2,
            branch_path: ["foo", "nested", "nested2"],
            branch_prefix: "/foo/nested/nested2"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/products/:id",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :root,
            language: "en",
            opt_attr: "default",
            branch_helper: nil,
            __branch__: [1, 0],
            branch_alias: nil,
            branch_path: [],
            branch_prefix: "/"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/foo/products/:id",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :root,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo",
            __branch__: [1, 1],
            branch_alias: :foo,
            branch_path: ["foo"],
            branch_prefix: "/foo"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/foo/nested/products/:id",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :n1,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo_nested",
            __branch__: [1, 2],
            branch_alias: :foo_nested,
            branch_path: ["foo", "nested"],
            branch_prefix: "/foo/nested"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/foo/nested/nested2/products/:id",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :n2,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo_nested_nested2",
            __branch__: [1, 3],
            branch_alias: :foo_nested_nested2,
            branch_path: ["foo", "nested", "nested2"],
            branch_prefix: "/foo/nested/nested2"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/posts/:id",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :root,
            language: "en",
            opt_attr: "default",
            branch_helper: nil,
            __branch__: [2, 0],
            alternatives_prefix: false,
            branch_alias: nil,
            branch_path: [],
            branch_prefix: "/"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/posts/:id",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :root,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo",
            __branch__: [2, 1],
            alternatives_prefix: false,
            branch_alias: :foo,
            branch_path: ["foo"],
            branch_prefix: "/foo"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/posts/:id",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :n1,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo_nested",
            __branch__: [2, 2],
            alternatives_prefix: false,
            branch_alias: :foo_nested,
            branch_path: ["foo", "nested"],
            branch_prefix: "/foo/nested"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      },
      %Routex.Route{
        verb: :get,
        line: nil,
        kind: nil,
        path: "/posts/:id",
        hosts: nil,
        plug: nil,
        plug_opts: nil,
        helper: nil,
        private: %{
          routex: %{
            key: :n2,
            language: "en",
            opt_attr: "default",
            branch_helper: "foo_nested_nested2",
            __branch__: [2, 3],
            alternatives_prefix: false,
            branch_alias: :foo_nested_nested2,
            branch_path: ["foo", "nested", "nested2"],
            branch_prefix: "/foo/nested/nested2"
          }
        },
        pipe_through: nil,
        assigns: nil,
        metadata: nil,
        trailing_slash?: nil,
        warn_on_verify?: nil
      }
    ]

    assert expected == Alternatives.transform(routes, Conf1, __ENV__)
  end
end
