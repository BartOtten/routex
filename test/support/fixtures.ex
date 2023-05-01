defmodule Routex.Test.Fixtures.Assigns do
  defstruct [:key, locale: "en", opt_attr: "default"]
end

defmodule Routex.Test.Fixtures do
  alias Routex.Extension.Alternatives.Scope
  alias __MODULE__.Assigns

  def scopes_with_map_attrs,
    do: %{
      "/" => %{
        attrs: %{key: :root, locale: "en", opt_attr: "default"},
        scopes: %{
          "/foo" => %{
            attrs: %{
              locale: "en",
              key: :root
            },
            scopes: %{
              "/nested" => %{
                attrs: %{key: :n1, locale: "en"},
                scopes: %{
                  "/nested2" => %{attrs: %{key: :n2, locale: "en"}}
                }
              }
            }
          }
        }
      }
    }

  def scopes,
    do: %{
      "/" => %{
        attrs: %Assigns{key: :root, locale: "en"},
        scopes: %{
          "/foo" => %{
            attrs: %Assigns{
              locale: "en",
              key: :root
            },
            scopes: %{
              "/nested" => %{
                attrs: %Assigns{key: :n1, locale: "en"},
                scopes: %{
                  "/nested2" => %{attrs: %Assigns{key: :n2, locale: "en"}}
                }
              }
            }
          }
        }
      }
    }

  def scopes_precomputed,
    do: %{
      nil => %Scope.Nested{
        attrs: %{scope_helper: nil, key: :root, locale: "en", opt_attr: "default"},
        scope_path: [],
        scope_alias: nil,
        scope_prefix: "/",
        scopes: %{
          "foo" => %Scope.Nested{
            attrs: %{opt_attr: "default", locale: "en", key: :root, scope_helper: "foo"},
            scopes: %{
              "nested" => %Scope.Nested{
                attrs: %{
                  opt_attr: "default",
                  locale: "en",
                  key: :n1,
                  scope_helper: "foo_nested"
                },
                scopes: %{
                  "nested2" => %Scope.Nested{
                    attrs: %{
                      opt_attr: "default",
                      locale: "en",
                      key: :n2,
                      scope_helper: "foo_nested_nested2"
                    },
                    scope_path: ["foo", "nested", "nested2"],
                    scope_alias: :nested2,
                    scope_prefix: "/nested2",
                    scopes: %{}
                  }
                },
                scope_path: ["foo", "nested"],
                scope_alias: :nested,
                scope_prefix: "/nested"
              }
            },
            scope_path: ["foo"],
            scope_alias: :foo,
            scope_prefix: "/foo"
          }
        }
      }
    }

  def scopes_flat,
    do: %{
      nil => %Scope.Flat{
        attrs: %{scope_helper: nil, key: :root, locale: "en", opt_attr: "default"},
        scope_path: [],
        scope_alias: nil,
        scope_prefix: "/"
      },
      "foo" => %Scope.Flat{
        scope_path: ["foo"],
        attrs: %{opt_attr: "default", locale: "en", key: :root, scope_helper: "foo"},
        scope_alias: :foo,
        scope_prefix: "/foo"
      },
      "foo_nested" => %Scope.Flat{
        scope_path: ["foo", "nested"],
        attrs: %{opt_attr: "default", locale: "en", key: :n1, scope_helper: "foo_nested"},
        scope_alias: :foo_nested,
        scope_prefix: "/foo/nested"
      },
      "foo_nested_nested2" => %Scope.Flat{
        attrs: %{
          opt_attr: "default",
          locale: "en",
          key: :n2,
          scope_helper: "foo_nested_nested2"
        },
        scope_path: ["foo", "nested", "nested2"],
        scope_alias: :foo_nested_nested2,
        scope_prefix: "/foo/nested/nested2"
      }
    }
end
