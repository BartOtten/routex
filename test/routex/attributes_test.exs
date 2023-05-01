defmodule Routex.AttributesTest do
  use ExUnit.Case, async: true

  alias Phoenix.Router.Route
  import Routex.Attrs

  test "is_private" do
    assert is_private(:__priv__)
    refute is_private(:priv)
    assert is_private({:__priv__, "value"})
    refute is_private({:priv, "value"})
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
    route = %Route{private: %{routex: %{__order__: [1, 2], other: "other"}}}
    result = route |> update(&Enum.reject(&1, fn {k, _v} -> k == :__order__ end))

    assert %Route{private: %{routex: %{other: "other"}}} = result
    refute match?(%Route{private: %{routex: %{__order__: _}}}, result)
  end

  test "update/2 updates the attr  with `key` using a function" do
    route = %Route{private: %{routex: %{__order__: [1, 2]}}}
    result = route |> update(:__order__, &List.insert_at(&1, -1, 3))

    assert %Route{private: %{routex: %{__order__: [1, 2, 3]}}} = result
  end

  describe "merge" do
    test "a list value" do
      route = %Route{private: %{routex: %{__order__: [1, 2]}}}
      result = merge(route, __order__: [5, 6], some: "some", other: "other")

      assert %Route{private: %{routex: %{__order__: [5, 6], some: "some", other: "other"}}} =
               result
    end

    test "a map value" do
      route = %Route{private: %{routex: %{__order__: [1, 2]}}}
      result = merge(route, %{__order__: [5, 6], some: "some", other: "other"})

      assert %Route{private: %{routex: %{__order__: [5, 6], some: "some", other: "other"}}} =
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
  end

  describe "test!" do
    test "raises when attr not found" do
      route = %Route{private: %{routex: %{some: "bar", foo: "baz"}}}
      assert_raise RuntimeError, fn -> get!(route, :non_existing, "Key not found yaw!") end
    end
  end
end
