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
    test "should handle nested lists" do
      assert "foo/bar/baz/qux" == join(["foo", ["bar", "baz"], "qux"])
    end

    test "should ignore nil segments" do
      assert "test" == join([nil, "test", nil])
      assert "/test" == join([nil, "/test", nil])
    end

    test "should convert integers and atoms to binary" do
      assert "foo/bar/8/:atom" == join(["foo", "bar", 8, :atom])
    end

    test "should not remove trailing query separator or fragment seperator" do
      assert "test?" == join([nil, "test", nil, "?"])
      assert "test#" == join([nil, "test", nil, "#"])
    end

    test "should deduplicate path seperators" do
      assert "/test/foo" == join(["//test/", "/foo"])
    end

    test "should preserve trailing slashes" do
      assert "test/foo/" == join(["test", "foo/"])
      assert "test/foo" == join(["test", "foo"])
    end

    test "should support both absolute and relative paths" do
      assert "test/foo" == join(["test", "foo"])
      assert "/test/foo" == join(["/test", "foo"])
    end

    test "should seperate segments by the correct separator" do
      assert "foo/bar" == join(["foo", "bar"])
      assert "foo/bar/3" == join(["foo", "bar", 3])
      assert "foo/bar/3?foo=baz" == join(["foo", "bar", 3, "?foo=baz"])
      assert "foo/bar/3/?foo=baz" == join(["foo", "bar", 3, "/?foo=baz"])
      assert "foo/bar/3#frag" == join(["foo", "bar", 3, "#frag"])
      assert "foo/bar/3/#frag" == join(["foo", "bar", 3, "/#frag"])
      assert "foo/bar/3?foo=baz#frag" == join(["foo", "bar", 3, "?foo=baz", "#frag"])
      assert "foo/bar/3/?foo=baz#frag" == join(["foo", "bar", 3, "/?foo=baz", "#frag"])
    end

    test "should support interpolation AST segments" do
      ast =
        quote do
          "#{interpolate}"
        end

      assert ~S"test/#{interpolate}/bar" == join(["test", ast, "bar"])
      assert ~S"test/#{interpolate}" == join(["test", ast])
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

    test "mimmick Plug.Router.Utils.split" do
      assert split("/foo/bar") ==
               ["foo", "bar"]

      assert split("/:id/*") ==
               [":id", "*"]

      assert split("/foo//*_bar") ==
               ["foo", "*_bar"]
    end

    test "preserves slashes when asked to" do
      assert ["/", "foo/", "bar/"] == split("/foo/bar/", preserve_separator: true)
      assert ["/", "foo/", "bar"] == split("/foo/bar", preserve_separator: true)
      assert ["foo/", "bar"] == split("foo/bar", preserve_separator: true)
    end

    test "returns empty list when root is given" do
      assert [] == split("/")
    end

    test "splits on interpolation" do
      assert ["test", ":interpolate", "bar"] == split("/test/:interpolate/bar")

      ast =
        quote do
          "#{interpolate}"
        end

      assert ["test", ast, "bar"] == split(~S"/test/#{interpolate}/bar")
      assert ["test", ast] == split(~S"/test/#{interpolate}")
    end

    test "pushes trailing slash of interpolated to a new segment" do
      assert ["test/", ":interpolated", "/", "bar"] =
               split("test/:interpolated/bar", preserve_separator: true)

      assert ["test/", ":interpolated", "/", ":some", "/", ":more", "/", "bar"] =
               split("test/:interpolated/:some/:more/bar", preserve_separator: true)

      ast =
        quote do
          "#{interpolate}"
        end

      assert ["/", "test/", ast, "/", ":some", "/", "bar"] ==
               split(~S"/test/#{interpolate}/:some/bar", preserve_separator: true)
    end
  end

  describe "split and join" do
    test "are matching molds" do
      urls = [
        "/foo/bar",
        "/foo/bar?baz=12",
        "/foo/bar/?baz=12",
        "/foo/bar#frag",
        "/foo/bar?baz=some#frag",
        "/foo/:iterpolate/bar",
        "/foo/:iterpolate/",
        "/foo/:iterpolate",
        ~S"/foo/#{binding}/bar",
        ~S"/foo/#{binding}"
      ]

      for url <- urls do
        assert url |> split(preserve_separator: true) |> join() == url
        assert url |> relative() |> split(preserve_separator: true) |> join() == url |> relative()
      end
    end
  end

  describe "to_match_pattern/1" do
    test "builds uniform match for different types of input" do
      path_ast = quote do: "/products/#{product}/baz"
      path_binary = "/products/:id/baz"
      path_list = ["products", ":id", "baz"]

      assert to_match_pattern(path_binary) == to_match_pattern(path_list)
      assert to_match_pattern(path_binary) == to_match_pattern(path_ast)
    end

    test "builds uniform match for different queries" do
      paths = [
        "/products/:id/show/edit?_action=delete",
        "/products/:id/show/edit?_action=submit",
        "/products/:id/show/edit?_action=update"
      ]

      assert all_equal(paths, &to_match_pattern/1)
    end

    test "builds uniform match for different fragments" do
      paths = [
        "/products/:id/show/edit#delete",
        "/products/:id/show/edit#submit",
        "/products/:id/show/edit#update"
      ]

      assert all_equal(paths, &to_match_pattern/1)
    end

    test "builds uniform match for different fragments (list)" do
      paths = [
        quote(do: "/products/#{product}/baz#delete"),
        "/products/:id/baz#delete",
        ["/products/", ":id", "/baz", "#delete"]
      ]

      assert all_equal(paths, &to_match_pattern/1)
    end
  end

  describe "join_statics" do
    test "simple forms" do
      assert ["foo/bar"] == join_statics(["foo", "bar"])
      assert ["foo/bar/3"] == join_statics(["foo", "bar", 3])
      assert ["foo/bar/4"] == join_statics(["foo", "bar", "4"])
      assert ["foo/bar?foo=bar"] == join_statics(["foo", "bar", "?foo=bar"])
      assert ["foo/bar/?foo=bar"] == join_statics(["foo", "bar", "/?foo=bar"])
      assert ["foo/bar#frag"] == join_statics(["foo", "bar", "#frag"])
      assert ["foo/bar/#frag"] == join_statics(["foo", "bar", "/#frag"])
      assert ["3/bar/#frag"] == join_statics([3, "bar", "/#frag"])
      assert ["foo/3#frag"] == join_statics(["foo", 3, "#frag"])
      assert ["/foo/3#frag"] == join_statics(["/foo", 3, "#frag"])
    end

    test "does not join interpolation values" do
      assert ["foo/bar", ":id", "baz"] == join_statics(["foo", "bar", ":id", "baz"])
    end

    test "accepts binary path" do
      assert ["/foo/bar/", ":id", "/baz"] == join_statics("/foo/bar/:id/baz")
    end

    test "keeps trailing slash (un)set" do
      assert [
               "/posts/",
               {:"::", [line: 151, column: 47],
                [
                  {{:., [line: 151, column: 47], [Kernel, :to_string]},
                   [from_interpolation: true, line: 151, column: 47],
                   [{:id, [line: 151, column: 49], nil}]},
                  {:binary, [line: 151, column: 47], nil}
                ]},
               "?foo=bar"
             ] ==
               join_statics([
                 "/posts/",
                 {:"::", [line: 151, column: 47],
                  [
                    {{:., [line: 151, column: 47], [Kernel, :to_string]},
                     [from_interpolation: true, line: 151, column: 47],
                     [{:id, [line: 151, column: 49], nil}]},
                    {:binary, [line: 151, column: 47], nil}
                  ]},
                 "?foo=bar"
               ])
    end
  end

  describe "recompose" do
    test "returns onchanged on exact matches" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/products/show/:id/edit/:foo"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit/#{some}"
        end

      {:<<>>, [], expected} =
        quote do
          "/products/show/#{x1}/edit/#{some}"
        end

      assert expected == recompose(orig_path, new_path, segments) |> join_statics()
    end

    test "returns correct order" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/:id/:foo/products/show/edit"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit/#{some}"
        end

      {:<<>>, [], expected} =
        quote do
          "/#{x1}/#{some}/products/show/edit"
        end

      assert expected == recompose(orig_path, new_path, segments) |> join_statics()
    end

    test "keeps query params" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/:id/:foo/products/show/edit"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit/#{some}?query_param=baz"
        end

      {:<<>>, [], expected} =
        quote do
          "/#{x1}/#{some}/products/show/edit?query_param=baz"
        end

      assert expected == recompose(orig_path, new_path, segments) |> join_statics()
    end

    test "keeps fragments" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/:id/:foo/products/show/edit"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit/#{some}#fragment"
        end

      {:<<>>, [], expected} =
        quote do
          "/#{x1}/#{some}/products/show/edit#fragment"
        end

      assert expected == recompose(orig_path, new_path, segments) |> join_statics()
    end

    test "keeps interpolated query params" do
      orig_path = "/products/show/:id/edit/:foo"
      new_path = "/:id/:foo/products/show/edit/"

      {:<<>>, [], segments} =
        quote do
          "/products/show/#{x1}/edit/#{some}/?#{%{foo: "bar"}}"
        end

      {:<<>>, [], expected} =
        quote do
          "/#{x1}/#{some}/products/show/edit/?#{%{foo: "bar"}}"
        end

      assert expected == recompose(orig_path, new_path, segments) |> join_statics()
    end
  end
end
