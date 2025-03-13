defmodule Routex.AttributesTest do
  use ExUnit.Case, async: true

  alias Phoenix.Router.Route
  import Routex.Attrs

  test "private?" do
    assert private?(:__priv__)
    refute private?(:priv)
    assert private?({:__priv__, "value"})
    refute private?({:priv, "value"})
  end

  describe "cleanup/1" do
    test "removes non private fields from a route's attrs" do
      route = %Route{private: %{routex: %{__priv__: "some", pub: "other"}}}
      assert %Route{private: %{routex: %{__priv__: "some"}}} = route |> cleanup()
    end

    test "removes non private fields an attrs map" do
      map = %{__priv__: "some", pub: "other"}
      assert %{__priv__: "some"} = map |> cleanup()
    end
  end

  test "update/2 updates the list of attributes using a function" do
    route = %Route{private: %{routex: %{__branch__: [1, 2], other: "other"}}}
    result = route |> update(&Enum.reject(&1, fn {k, _v} -> k == :__branch__ end))

    assert %Route{private: %{routex: %{other: "other"}}} = result
    refute match?(%Route{private: %{routex: %{__branch__: _}}}, result)
  end

  test "update/2 updates the attr  with `key` using a function" do
    route = %Route{private: %{routex: %{__branch__: [1, 2]}}}
    result = route |> update(:__branch__, &List.insert_at(&1, -1, 3))

    assert %Route{private: %{routex: %{__branch__: [1, 2, 3]}}} = result
  end

  describe "merge" do
    test "a list value" do
      route = %Route{private: %{routex: %{__branch__: [1, 2]}}}
      result = merge(route, __branch__: [5, 6], some: "some", other: "other")

      assert %Route{private: %{routex: %{__branch__: [5, 6], some: "some", other: "other"}}} =
               result
    end

    test "a map value" do
      route = %Route{private: %{routex: %{__branch__: [1, 2]}}}
      result = merge(route, %{__branch__: [5, 6], some: "some", other: "other"})

      assert %Route{private: %{routex: %{__branch__: [5, 6], some: "some", other: "other"}}} =
               result
    end
  end

  describe "put" do
    test "initial value" do
      route = %Route{}

      assert %Route{private: %{routex: %{some: "some"}}} == put(route, %{some: "some"})
      assert %Route{private: %{routex: %{some: "some"}}} == put(route, :some, "some")
    end

    test "overwrite all attrs" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}

      assert %Route{private: %{routex: %{some: "some"}}} == put(route, %{some: "some"})
    end

    test "overwrite only attr key" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert %Route{private: %{routex: %{some: "some", foo: "baz"}}} == put(route, :some, "some")
    end
  end

  describe "get" do
    test "without a key" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert %{some: "bar", foo: "baz"} == get(route)
    end

    test "without a key, attrs not available" do
      route = %Route{private: %{}}
      assert %{} == get(route)
    end

    test "without a key, uses fallback when attrs not available" do
      route = %Route{private: %{}}
      assert "fallback" == get(route, nil, "fallback")
    end

    test "with a key" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert "bar" == get(route, :some)
    end

    test "uses the fallback when no routex attrs are set" do
      route = %Route{private: %{}}
      assert "fallback" == get(route, :non_existing, "fallback")
    end

    test "uses the fallback when attr not found" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert "fallback" == get(route, :non_existing, "fallback")
    end

    test "handles conn" do
      route = %Plug.Conn{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert "bar" == get(route, :some)
    end

    test "handles socket" do
      route = %Phoenix.Socket{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert "bar" == get(route, :some)
    end

    test "handles map" do
      route = %{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert "bar" == get(route, :some)
    end
  end

  describe "get!" do
    test "with a key" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert "bar" == get!(route, :some)
    end

    test "raises when no routex attrs are set" do
      route = %Route{private: %{}}
      assert_raise(RuntimeError, fn -> get!(route, :non_existing) end)
    end

    test "raises when attr not found" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert_raise(RuntimeError, fn -> get!(route, :non_existing) end)
    end

    test "raises with custom message" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert_raise(RuntimeError, "my failure", fn -> get!(route, :non_existing, "my failure") end)
    end
  end
end
