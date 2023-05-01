defmodule Routex.Extension.AlternativeGettersTest do
  use ExUnit.Case, async: true

  alias Routex.Extension.AlternativeGetters
  require ListAssertions

  @expected [
    %AlternativeGetters{
      slug: "/products/12?foo=baz",
      attrs: %{}
    },
    %AlternativeGetters{
      slug: "/europe/products/12?foo=baz",
      attrs: %{}
    },
    %AlternativeGetters{
      slug: "/europe/be/producten/12?foo=baz",
      attrs: %{}
    },
    %AlternativeGetters{
      slug: "/europe/nl/producten/12?foo=baz",
      attrs: %{}
    },
    %AlternativeGetters{
      slug: "/gb/products/12?foo=baz",
      attrs: %{}
    }
  ]

  test "returns self and siblings" do
    ListAssertions.assert_unordered(
      @expected,
      MyAppWeb.MultiLangRouter.RoutexHelpers.alternatives("/products/12?foo=baz")
    )

    ListAssertions.assert_unordered(
      @expected,
      MyAppWeb.MultiLangRouter.RoutexHelpers.alternatives(
        ["products", "12"],
        "foo=baz"
      )
    )
  end

  test "does compile" do
    # routes = [
    #   %Phoenix.Router.Route{path: "/", private: %{routex: %{__order__: [0]}}},
    #   %Phoenix.Router.Route{path: "/page", private: %{routex: %{__order__: [0, 1]}}},
    #   %Phoenix.Router.Route{
    #     path: "/page/edit",
    #     private: %{routex: %{__order__: [0, 2]}}
    #   },
    #   %Phoenix.Router.Route{
    #     path: "/page_alt1",
    #     private: %{routex: %{__order__: [0, 1, 1]}}
    #   },
    #   %Phoenix.Router.Route{
    #     path: "/page_alt2",
    #     private: %{routex: %{__order__: [0, 1, 2]}}
    #   },
    #   %Phoenix.Router.Route{
    #     path: "/page/edit_alt1",
    #     private: %{routex: %{__order__: [0, 2, 1]}}
    #   }
    # ]

    # AlternativeGetters.create_helpers(routes, MyAppWeb.MultiLangRouter, :ignored)
    # |> Routex.ExtensionUtils.inspect_ast()
  end
end
