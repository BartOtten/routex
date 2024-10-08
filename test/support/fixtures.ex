defmodule Routex.Test.Fixtures.Assigns do
  defstruct [:key, language: "en", opt_attr: "default"]
end

defmodule Routex.Test.Fixtures do
  alias Routex.Extension.Alternatives.Branch
  alias __MODULE__.Assigns

  def branches_with_map_attrs,
    do: %{
      "/" => %{
        attrs: %{key: :root, language: "en", opt_attr: "default"},
        branches: %{
          "/foo" => %{
            attrs: %{
              language: "en",
              key: :root
            },
            branches: %{
              "/nested" => %{
                attrs: %{key: :n1, language: "en"},
                branches: %{
                  "/nested2" => %{attrs: %{key: :n2, language: "en"}}
                }
              }
            }
          }
        }
      }
    }

  def branches,
    do: %{
      "/" => %{
        attrs: %Assigns{key: :root, language: "en"},
        branches: %{
          "/foo" => %{
            attrs: %Assigns{
              language: "en",
              key: :root
            },
            branches: %{
              "/nested" => %{
                attrs: %Assigns{key: :n1, language: "en"},
                branches: %{
                  "/nested2" => %{attrs: %Assigns{key: :n2, language: "en"}}
                }
              }
            }
          }
        }
      }
    }

  def branches_precomputed,
    do: %{
      nil => %Branch.Nested{
        attrs: %{branch_helper: nil, key: :root, language: "en", opt_attr: "default"},
        branch_path: [],
        branch_alias: nil,
        branch_prefix: "/",
        branches: %{
          "foo" => %Branch.Nested{
            attrs: %{opt_attr: "default", language: "en", key: :root, branch_helper: "foo"},
            branches: %{
              "nested" => %Branch.Nested{
                attrs: %{
                  opt_attr: "default",
                  language: "en",
                  key: :n1,
                  branch_helper: "foo_nested"
                },
                branches: %{
                  "nested2" => %Branch.Nested{
                    attrs: %{
                      opt_attr: "default",
                      language: "en",
                      key: :n2,
                      branch_helper: "foo_nested_nested2"
                    },
                    branch_path: ["foo", "nested", "nested2"],
                    branch_alias: :nested2,
                    branch_prefix: "/nested2",
                    branches: %{}
                  }
                },
                branch_path: ["foo", "nested"],
                branch_alias: :nested,
                branch_prefix: "/nested"
              }
            },
            branch_path: ["foo"],
            branch_alias: :foo,
            branch_prefix: "/foo"
          }
        }
      }
    }

  def branches_flat,
    do: %{
      nil => %Branch.Flat{
        attrs: %{branch_helper: nil, key: :root, language: "en", opt_attr: "default"},
        branch_path: [],
        branch_alias: nil,
        branch_prefix: "/"
      },
      "foo" => %Branch.Flat{
        branch_path: ["foo"],
        attrs: %{opt_attr: "default", language: "en", key: :root, branch_helper: "foo"},
        branch_alias: :foo,
        branch_prefix: "/foo"
      },
      "foo_nested" => %Branch.Flat{
        branch_path: ["foo", "nested"],
        attrs: %{opt_attr: "default", language: "en", key: :n1, branch_helper: "foo_nested"},
        branch_alias: :foo_nested,
        branch_prefix: "/foo/nested"
      },
      "foo_nested_nested2" => %Branch.Flat{
        attrs: %{
          opt_attr: "default",
          language: "en",
          key: :n2,
          branch_helper: "foo_nested_nested2"
        },
        branch_path: ["foo", "nested", "nested2"],
        branch_alias: :foo_nested_nested2,
        branch_prefix: "/foo/nested/nested2"
      }
    }
end
