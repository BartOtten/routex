defmodule Routex.Extension.InterpolationTest do
  use ExUnit.Case

  alias Phoenix.Router.Route

  import Routex.Extension.Interpolation

  @routes [
    %Route{
      line: 1,
      path: "/path/[rtx.language]",
      verb: :get,
      private: %{routex: %{__origin__: "/path", language: :nl}}
    },
    %Route{
      line: 8,
      path: "/path/[rtx.language]",
      verb: :get,
      private: %{routex: %{__origin__: "/path", language: :en}}
    },
    %Route{
      line: 30,
      path: "/path/new",
      verb: :get,
      private: %{routex: %{__origin__: "/no/interpolation"}}
    }
  ]

  test "should interpolate when attrs provided" do
    assert [%{path: "/path/nl"}, %{path: "/path/en"}, %{path: "/path/new"}] =
             transform(@routes, nil, nil)
  end

  test "should fail when attrs missing" do
    [r1 | _] = @routes
    r1 = %{r1 | path: "/path/[rtx.missing]"}
    exception = assert_raise RuntimeError, fn -> transform([r1], nil, nil) end
    assert exception.message =~ "key :missing"
  end

  test "should raise on duplicate routes after interpolation" do
    routes = [
      %Route{
        line: 20,
        path: "/path/[rtx.language]",
        verb: :get,
        private: %{routex: %{__origin__: "/foo", language: :en}}
      }
      | @routes
    ]

    exception =
      assert_raise Routex.Extension.Interpolation.NonUniqError, fn ->
        transform(routes, nil, nil)
      end

    assert [
             {{:get, "/path/en"},
              [%{verb: :get, path: "/path/en"}, %{verb: :get, path: "/path/en"}]}
           ] = exception.duplicated
  end
end
