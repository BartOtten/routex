defmodule MatchTest.Constants do
  @moduledoc """
  A module to be use'd to import shared attributes
  """
  defmacro __using__(_) do
    quote do
      @route %Phoenix.Router.Route{
        hosts: [],
        path: "/:category/products/:id/edit",
        trailing_slash?: false
      }

      @product_route_spanish %Phoenix.Router.Route{
        hosts: [],
        path: "/:id/:category/producta/edito",
        trailing_slash?: false
      }

      @product_route_dutch %Phoenix.Router.Route{
        hosts: [],
        path: "/:category/producten/wijzigen/:id",
        trailing_slash?: false
      }

      @uri_matches (for scheme <- ["http", "https", "ftp"],
                        host <- ["localhost"],
                        path <- ["/games/products/12/edit"],
                        query <- [nil, "k=v"],
                        fragment <- [nil, "top"] do
                      to_string(%URI{
                        scheme: scheme,
                        host: host,
                        path: path,
                        query: query,
                        fragment: fragment
                      })
                    end)

      @sigil_matches (for p1 <- ["/games/products/"],
                          p2 <- [quote(do: "#{%{id: 12}}")],
                          p3 <- [
                            "/edit",
                            "/edit?k=v",
                            ["/edit?", quote(do: "#{%{k: "v"}}")],
                            "/edit#top"
                          ] do
                        {:<<>>, [], [p1, p2, p3]}
                      end)
    end
  end
end

defmodule MatchTest.Setup do
  @moduledoc """
   Creates a module used for testing compiled functions and patterns.
  """
  use MatchTest.Constants
  alias Routex.Match

  # create a compiled module which we can use for matching. The module has tre functions: recompose/2, route/1 and testvar/2.
  route_definition_ast = quote do: unquote(@route |> Macro.escape())
  recompose_ast_sp = quote do: unquote(Match.to_pattern(@product_route_spanish))
  recompose_ast_nl = quote do: unquote(Match.to_pattern(@product_route_dutch))
  binding_ast = quote do: "binding_is_" <> unquote(Macro.var(:var, Match))

  ast = [
    Match.to_func(@route, :recompose, [var: "nl"], recompose_ast_nl),
    Match.to_func(@route, :recompose, [var: "sp"], recompose_ast_sp),
    quote do
      def recompose(input) when is_tuple(input), do: {:not_found, input}
      def recompose(input), do: {:error, :invalid_input_format}
    end,
    Match.to_func(@route, :route, route_definition_ast),
    quote do
      def route(input) when is_tuple(input), do: {:not_found, input}
      def route(input), do: {:error, :invalid_input_format}
    end,
    Match.to_func(@route, :testvar, [:var], binding_ast)
  ]

  Module.create(MatchTest.Setup.Compiled, ast, __ENV__)
end

defmodule MatchTest do
  use ExUnit.Case
  use MatchTest.Constants

  alias __MODULE__.Setup.Compiled
  alias Routex.Match

  def route(input), do: Map.merge(%Phoenix.Router.Route{}, Map.new(input))
  def ast(input), do: {:<<>>, [], input}

  describe "new/1" do
    test "uses same defaults for all types" do
      routes = [route(path: "/some"), "/some", {:<<>>, [], ["/some"]}]

      for route <- routes do
        assert Match.new(route) == {:match, [], ["/", "some"], [], []}
      end
    end

    test "returns correct match on root path" do
      routes = [
        route(path: "/", trailing_slash?: true),
        "/",
        ast(["/"])
      ]

      for route <- routes do
        assert Match.new(route) == {:match, [], ["/"], [], []}
      end
    end

    test "correctly splits query and fragment parts" do
      route = "/products/1?foo=bar#top"
      assert Match.new(route) == {:match, [], ["/", "products", "/", "1"], ["?foo=bar"], ["#top"]}
    end

    test "correctly splits query part in AST node" do
      static_route = {:<<>>, [], ["/products/1?foo=bar#top"]}

      assert Match.new(static_route) ==
               {:match, [], ["/", "products", "/", "1"], ["?", "foo=bar"], ["#", "top"]}

      dynamic_route =
        ast([
          "/products/1/edit?",
          {:"::", [],
           [
             {{:., [], [Kernel, :to_string]}, [from_interpolation: true],
              [{:%{}, [], [foo: "bar"]}]},
             {:binary, [], Elixir}
           ]},
          "#top"
        ])

      assert Match.new(dynamic_route) ==
               {
                 :match,
                 [],
                 ["/", "products", "/", "1", "/", "edit"],
                 [
                   "?",
                   {:"::", [],
                    [
                      {{:., [], [Kernel, :to_string]}, [from_interpolation: true],
                       [{:%{}, [], [foo: "bar"]}]},
                      {:binary, [], Elixir}
                    ]}
                 ],
                 ["#", "top"]
               }
    end
  end

  describe "to_binary/1" do
    test "returns a binary matching the path, query and fragment of the original url" do
      for uri <- @uri_matches do
        expected = URI.parse(uri)

        result =
          uri
          |> Match.new()
          |> Match.to_binary()
          |> URI.parse()

        assert result.query == expected.query
        assert result.fragment == expected.fragment
        assert result.path == expected.path
      end
    end
  end

  describe "match?" do
    test "returns 'true' for matching records" do
      matching = @uri_matches ++ @sigil_matches

      for uri <- matching do
        m1 = Routex.Match.new(@route)
        m2 = Routex.Match.new(uri)

        assert Routex.Match.match?(m1, m2) == true,
               "#{inspect(uri, pretty: true)} does not match #{inspect(@route, pretty: true)} \n\n m1: #{inspect(m1, pretty: true)}\n m2: #{inspect(m2, pretty: true)}"
      end
    end
  end

  describe "to_pattern/1 and to_function/2" do
    test "compiled body patterns are in line with compiled head patterns" do
      # This tests the compiled functions which were created with to_function/1 (which creates a pattern matching function head) and a body created with to_pattern/2 (which creates a pattern including head matching bindings).
      for uri <- @uri_matches do
        expected = URI.parse(uri)

        result =
          uri
          |> Match.new()
          |> Compiled.recompose("sp")
          |> Match.to_binary()
          |> URI.parse()

        assert result.query == expected.query
        assert result.fragment == expected.fragment
        assert result.path == "/12/games/producta/edito"

        result =
          uri
          |> Match.new()
          |> Compiled.recompose("nl")
          |> Match.to_binary()
          |> URI.parse()

        assert result.query == expected.query
        assert result.fragment == expected.fragment
        assert result.path == "/games/producten/wijzigen/12"
      end
    end

    test "accept catchall var in the arguments" do
      # This tests a compile function which is created with to_function/1 (which creates a route pattern matching function head with a catchall argument) and a custom body which matches the
      # given variable name.
      route_match =
        @route
        |> Match.new()

      result = Compiled.testvar(route_match, "var-value")
      assert result == "binding_is_var-value"
    end

    test "non-matching route returns the value from the defined catch-all function" do
      route_mismatch = route(path: "/non-matching") |> Match.new()
      result = Compiled.route(route_mismatch)
      assert {:not_found, {:match, [], ["/", "non-matching"], [], []}} == result

      route_misformed = "/misformed"
      result = Compiled.route(route_misformed)
      assert {:error, :invalid_input_format} == result
    end
  end
end
