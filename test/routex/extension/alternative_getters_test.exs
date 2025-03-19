defmodule Routex.Extension.AlternativeGettersTest do
  use ExUnit.Case, async: true

  alias Routex.Extension.AlternativeGetters
  alias Routex.Extension.AttrGetters
  import ListAssertions

  routes = [
    %Phoenix.Router.Route{
      path: "/",
      kind: :match,
      private: %{routex: %{__branch__: [0]}}
    },
    %Phoenix.Router.Route{
      path: "/products",
      kind: :match,
      private: %{routex: %{__branch__: [1, 0]}}
    },
    %Phoenix.Router.Route{
      path: "/alt1/productsa",
      kind: :match,
      private: %{routex: %{__branch__: [1, 1]}}
    },
    %Phoenix.Router.Route{
      path: "/alt2/productsb",
      kind: :match,
      private: %{routex: %{__branch__: [1, 2]}}
    },
    %Phoenix.Router.Route{
      path: "/products/:id",
      kind: :match,
      private: %{routex: %{__branch__: [2, 0]}}
    },
    %Phoenix.Router.Route{
      path: "/alt1/:id/productsa/",
      kind: :match,
      private: %{routex: %{__branch__: [2, 1]}}
    },
    %Phoenix.Router.Route{
      path: "/alt2/:id/productsb/",
      kind: :match,
      private: %{routex: %{__branch__: [2, 2]}}
    }
  ]

  ast_attrs = AttrGetters.create_helpers(routes, __MODULE__, :ignored)
  ast_alt = AlternativeGetters.create_helpers(routes, __MODULE__, :ignored)
  Module.create(__MODULE__.RoutexHelpers, [ast_attrs, ast_alt], __ENV__)

  @expected [
    %AlternativeGetters{
      slug: "/products/12?foo=baz#top",
      match?: true,
      attrs: %{}
    },
    %AlternativeGetters{
      slug: "/alt1/12/productsa/?foo=baz#top",
      match?: false,
      attrs: %{}
    },
    %AlternativeGetters{
      slug: "/alt2/12/productsb/?foo=baz#top",
      match?: false,
      attrs: %{}
    }
  ]

  test "returns self and siblings" do
    import __MODULE__.RoutexHelpers
    assert_unordered(@expected, alternatives("/products/12?foo=baz#top"))
  end
end
