defmodule Routex.PathTest do
  use ExUnit.Case
  import Routex.Path
  doctest Routex.Path, except: [pattern: 2]

  defp all_equal(list, func) do
    result =
      list
      |> Enum.map(&func.(&1))
      |> Enum.reduce_while(nil, fn
        x, nil -> {:cont, x}
        x, x -> {:cont, x}
        x, y -> {:halt, {false, x, y}}
      end)

    refute match?({false, _, _}, result)

    true
  end

  describe "join/1" do
    test "returns root when an empty path is given" do
      assert "/" == join([])
    end

    test "accepts nested lists" do
      assert "/foo/bar/baz/qux" == join(["foo", ["bar", "baz"], "qux"])
    end

    test "ignores nil segments" do
      assert "/test" == join([nil, "/test", nil])
    end

    test "converts integers and atoms to binary" do
      assert "/foo/bar/8/:atom" == join(["foo", "bar", 8, :atom])
    end

    test "removes trailing query separator" do
      assert "/test" == join([nil, "/test", nil, "?"])
    end

    test "the path starts with the root indicator" do
      assert "/foo" == join(["foo"])
    end

    test "segments are seperated by the correct separator" do
      assert "/foo/bar" == join(["foo", "bar"])
      assert "/foo/bar/3" == join(["foo", "bar", 3])
      assert "/foo/bar/3?foo=baz" == join(["foo", "bar", 3, "?foo=baz"])
      assert "/foo/bar/3#frag" == join(["foo", "bar", 3, "#frag"])
    end
  end

  describe "split/1" do
    test "returns empty list when nil is given" do
      assert [] == split(nil)
    end

    test "preserves the query" do
      assert ["foo", "bar", "?baz=qux"] == split("/foo/bar?baz=qux")
    end

    test "preserves the fragment" do
      assert ["foo", "bar", "#foobar"] == split("/foo/bar#foobar")
    end

    test "returns empty list when root is given" do
      assert [] == split("/")
    end

    test "splits on interpolation" do
      assert ["some", ":interpolated", "path"] == split("/some/:interpolated/path")
    end
  end

  describe "split and join" do
    test "are matching molds" do
      urls = [
        "/foo/bar",
        "/foo/bar?baz=12",
        "/foo/bar#frag",
        "/foo/bar?baz=some#frag"
      ]

      for url <- urls do
        assert url |> split() |> join() == url
      end
    end
  end

  describe "build_path_match/1" do
    test "builds uniform match for different types of input" do
      path_ast = quote do: "/products/#{product}/baz"
      path_binary = "/products/:id/baz"
      path_list = ["products", ":id", "baz"]

      assert build_path_match(path_binary) == build_path_match(path_list)
      assert build_path_match(path_binary) == build_path_match(path_ast)
    end

    test "builds uniform match for different queries" do
      paths = [
        "/products/:id/show/edit?_action=delete",
        "/products/:id/show/edit?_action=submit",
        "/products/:id/show/edit?_action=update"
      ]

      assert all_equal(paths, &build_path_match/1)
    end

    test "builds uniform match for different fragments" do
      paths = [
        "/products/:id/show/edit#delete",
        "/products/:id/show/edit#submit",
        "/products/:id/show/edit#update"
      ]

      assert all_equal(paths, &build_path_match/1)
    end

    test "builds uniform match for different fragments (list)" do
      paths = [
        quote(do: "/products/#{product}/baz#delete"),
        "/products/:id/baz#delete",
        ["products", ":id", "baz", "#delete"]
      ]

      assert all_equal(paths, &build_path_match/1)
    end
  end

  describe "join_statics" do
    test "does not join interpolation values" do
      assert ["/foo/bar", ":id", "/baz"] == join_statics(["foo", "bar", ":id", "baz"])
    end

    test "accepts binary path" do
      assert ["/foo/bar", ":id", "/baz"] == join_statics("/foo/bar/:id/baz")
    end
  end

  describe "compose" do
    test "returns correct order" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/:id/:foo/products/show/edit"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit#{some}"
        end

      {:<<>>, [], expected} =
        quote do
          "/#{x1}/#{some}/products/show/edit"
        end

      assert expected == recompose(orig_path, new_path, segments)
    end

    test "keeps query params" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/:id/:foo/products/show/edit"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit#{some}/?query_param=baz"
        end

      {:<<>>, [], expected} =
        quote do
          "/#{x1}/#{some}/products/show/edit?query_param=baz"
        end

      assert expected == recompose(orig_path, new_path, segments)
    end

    test "keeps fragments" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/:id/:foo/products/show/edit"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit#{some}/#fragment"
        end

      {:<<>>, [], expected} =
        quote do
          "/#{x1}/#{some}/products/show/edit#fragment"
        end

      assert expected == recompose(orig_path, new_path, segments)
    end

    test "keeps interpolated query params" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/:id/:foo/products/show/edit"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit#{some}/?#{%{foo: "bar"}}"
        end

      {:<<>>, [], expected} =
        quote do
          "/#{x1}/#{some}/products/show/edit?#{%{foo: "bar"}}"
        end

      assert expected == recompose(orig_path, new_path, segments)
    end
  end
end
