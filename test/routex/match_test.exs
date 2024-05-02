defmodule MatchTest do
  use ExUnit.Case
  alias Routex.Match

  @route %Phoenix.Router.Route{
    hosts: [],
    path: "/:category/products/:id/edit",
    trailing_slash?: false
  }

  @alt_route_sp %Phoenix.Router.Route{
    hosts: [],
    path: "/:id/:category/producta/edito",
    trailing_slash?: false
  }

  @alt_route_nl %Phoenix.Router.Route{
    hosts: [],
    path: "/:category/producten/wijzigen/:id",
    trailing_slash?: false
  }

  @uri_matches (for scheme <- ["http", "https", "ftp"],
                    host <- ["localhost"],
                    path <- ["/games/products/12/edit"],
                    query <- [nil, "k=v"],
                    fragment <- [nil, "top"] do
                  %URI{scheme: scheme, host: host, path: path, query: query, fragment: fragment}
                end)

  @sigil_matches (for p1 <- ["/nl/products/"],
                      p2 <- [%{id: 12}],
                      p3 <- ["/edit", "/edit?k=v", "/edit#top"] do
                    [p1, p2, p3]
                  end)

  # create a compiled module which we can use for matching
  recompose_ast_sp = quote do: unquote(Match.to_pattern(@alt_route_sp))
  recompose_ast_nl = quote do: unquote(Match.to_pattern(@alt_route_nl))

  testvar_ast = quote do: "var_is_" <> unquote(Macro.var(:var, Match))

  route_definition_ast = quote do: unquote(@route |> Macro.escape())

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
    Match.to_func(@route, :testvar, [:var], testvar_ast)
  ]

  Module.create(__MODULE__.Compiled, ast, __ENV__)

  alias __MODULE__.Compiled
  alias Routex.Match

  test "URL matches Route" do
    for uri <- @uri_matches do
      result =
        uri
        |> Match.new()
        |> Compiled.recompose("sp")
        |> Match.to_binary()
        |> URI.parse()

      assert result.query == uri.query
      assert result.fragment == uri.fragment
      assert result.path == "/12/games/producta/edito"

      result =
        uri
        |> Match.new()
        |> Compiled.recompose("nl")
        |> Match.to_binary()
        |> URI.parse()

      assert result.query == uri.query
      assert result.fragment == uri.fragment
      assert result.path == "/games/producten/wijzigen/12"
    end
  end

  test "Catchall var can be added to the arguments" do
    result =
      @route
      |> Match.new()
      |> Compiled.testvar("var-value")

    assert result == "var_is_var-value"
  end
end

# ~"/some/path" must become a runtime call to sigil_p("/some/path", branch_from_socket_or_conn)

# def sigil_p([{:<<>>, _, segments, []]}) do
# 	alias Compiled
# 	quote do
# 		record = segments |> Match.new()
# 		# call branched variant
# 		Compiled.sigil_p(record, branch)
# 	end
# end

# def branched(record, branch) do

# 	for route <- @routes do
# 			#binds vars
# 		case {unquote(Match.to_pattern(route), branch} do
# 		{match_ast, "en"} -> Compiled.recompose(@en_route)
# 		{match_ast, "nl"} -> Compiled.recompose(@enl_route)
# 		end
# 	end
# end
# end
