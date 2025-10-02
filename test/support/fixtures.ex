defmodule Routex.Test.Fixtures.Assigns do
  defstruct [:custom_key, language: "en", opt_attr: "default"]
end

defmodule Routex.Test.Fixtures do
  alias Routex.Extension.Alternatives.Branch
  alias __MODULE__.Assigns

  def branches_with_map_attrs,
    do: %{
      "/" => %{
        attrs: %{custom_key: :root, language: "en", opt_attr: "default"},
        branches: %{
          "/foo" => %{
            attrs: %{
              language: "en",
              custom_key: :root
            },
            branches: %{
              "/nested" => %{
                attrs: %{custom_key: :n1, language: "en"},
                branches: %{
                  "/nested2" => %{attrs: %{custom_key: :n2, language: "en"}}
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
        attrs: %Assigns{custom_key: :root, language: "en"},
        branches: %{
          "/foo" => %{
            attrs: %Assigns{
              language: "en",
              custom_key: :root
            },
            branches: %{
              "/nested" => %{
                attrs: %Assigns{custom_key: :n1, language: "en"},
                branches: %{
                  "/nested2" => %{attrs: %Assigns{custom_key: :n2, language: "en"}}
                }
              }
            }
          }
        }
      }
    }

  def branches_precomputed,
    do: %{
      nil: %Branch.Nested{
        attrs: %{custom_key: :root, language: "en", opt_attr: "default"},
        branch_key: nil,
        branch_path: [],
        branch_prefix: "/",
        branches: %{
          "foo" => %Branch.Nested{
            attrs: %{custom_key: :root, language: "en", opt_attr: "default"},
            branch_key: "foo",
            branch_path: ["foo"],
            branch_prefix: "/foo",
            branches: %{
              "nested" => %Branch.Nested{
                attrs: %{custom_key: :n1, language: "en", opt_attr: "default"},
                branch_key: "nested",
                branch_path: ["foo", "nested"],
                branch_prefix: "/nested",
                branches: %{
                  "nested2" => %Branch.Nested{
                    attrs: %{custom_key: :n2, language: "en", opt_attr: "default"},
                    branch_key: "nested2",
                    branch_path: ["foo", "nested", "nested2"],
                    branch_prefix: "/nested2",
                    branches: %{}
                  }
                }
              }
            }
          }
        }
      }
    }

  def branches_flat,
    do: %{
      nil => %Branch.Flat{
        attrs: %{custom_key: :root, language: "en", opt_attr: "default"},
        branch_key: nil,
        branch_path: [],
        branch_prefix: "/"
      },
      "foo" => %Branch.Flat{
        attrs: %{custom_key: :root, language: "en", opt_attr: "default"},
        branch_key: "foo",
        branch_path: ["foo"],
        branch_prefix: "/foo"
      },
      "foo_nested" => %Branch.Flat{
        attrs: %{custom_key: :n1, language: "en", opt_attr: "default"},
        branch_key: "foo_nested",
        branch_path: ["foo", "nested"],
        branch_prefix: "/foo/nested"
      },
      "foo_nested_nested2" => %Branch.Flat{
        attrs: %{custom_key: :n2, language: "en", opt_attr: "default"},
        branch_key: "foo_nested_nested2",
        branch_path: ["foo", "nested", "nested2"],
        branch_prefix: "/foo/nested/nested2"
      }
    }
end
