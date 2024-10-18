defmodule Routex.Extension.InterpolationTest do
  use ExUnit.Case

  alias Phoenix.Router.Route
  alias Routex.Attrs

  import Routex.Extension.Interpolation

  @routes [
    %Route{
      line: 1,
      path: "/path/[rtx.language]",
      verb: :get,
      private: %{routex: %{__origin__: "/path/[rtx.language]", language: :nl, __branch__: [1, 1]}}
    },
    %Route{
      line: 8,
      path: "/path/[rtx.language]",
      verb: :get,
      private: %{routex: %{__origin__: "/path/[rtx.language]", language: :en, __branch__: [1, 0]}}
    },
    %Route{
      line: 30,
      path: "/path/new",
      verb: :get,
      private: %{routex: %{__origin__: "/no/interpolation", __branch__: [2, 0]}}
    }
  ]

  test "should interpolate only descendants when attrs provided" do
    assert [%{path: "/path/nl"}, %{path: "/path"}, %{path: "/path/new"}] =
             transform(@routes, nil, nil)
  end

  test "should fail when attr is missing" do
    [r1 | _] = @routes
    r1 = %{r1 | path: "/path/[rtx.my_missing_attr]"}
    exception = assert_raise RuntimeError, fn -> transform([r1], nil, nil) end
    assert exception.message =~ "key :my_missing_attr"
  end

  test "should raise on duplicate routes after interpolation" do
    routes = [
      %Route{
        line: 20,
        path: "/path/[rtx.language]",
        verb: :get,
        private: %{routex: %{__origin__: "/foo", language: :nl, __branch__: [3]}}
      }
      | @routes
    ]

    exception =
      assert_raise Routex.Extension.Interpolation.NonUniqError, fn ->
        transform(routes, nil, nil)
      end

    assert [
             {{:get, "/path/nl"},
              [%{verb: :get, path: "/path/nl"}, %{verb: :get, path: "/path/nl"}]}
           ] = exception.duplicated
  end

  test "sets origin without interpolation syntax" do
    routes = transform(@routes, nil, nil)
    assert routes |> Enum.at(0) |> Attrs.get(:__origin__) == "/path"
  end
end
