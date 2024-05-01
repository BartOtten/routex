defmodule Foo do
  @input "http://some.com/foo/12/bar?query=bar#fragment"
  @route "/foo/:id/bar"
  @to_route "/bar/foo/:id"

  def ctx, do: %{input: @input, route: @route}

  route_map =
    Routex.MatchMap.new(@route)
    |> Map.drop([:dynamic])
    |> Macro.escape()

  route_pattern =
    Routex.Path.to_match_pattern(@route)
    |> Routex.Path.split(strict: false)

  route_func =
    @route
    |> Routex.Match.new()
    |> Routex.Match.to_pattern()

  def match_test(unquote(route_map)), do: :ok
  def match_test(unquote(route_pattern)), do: :ok
  def match_test(unquote(route_func)), do: :ok
  # def match_test(unquote(route_func)) do
  #   unquote(Routex.Match.new(@to_route) |> Routex.Match.to_pattern() )  |> Routex.Match.to_binary()
  # end

  def match_test(some), do: raise(some)
end

defmodule Bar do
  Benchee.run(
    %{
      # "match_pattern" => fn ->
      #   :ok =
      # 		Foo.ctx().input
      # 		|> URI.parse()
      # 		|> Map.get(:path)
      #   |> Routex.Path.split(strict: false)
      #   |> Foo.match_test()
      # end,
      "match_map" => fn ->
        :ok =
          Foo.ctx().input
          |> Routex.MatchMap.new()
          |> Foo.match_test()
      end,
      "match_func" => fn ->
        t =
          Foo.ctx().input
          |> Routex.Match.new()
          |> Foo.match_test()
      end
    },
    time: 10,
    memory_time: 2
  )

  # @path "/home/var/some"

  # Benchee.run(%{
  # 	native: fn -> Path.split(@path) end
  # 		routex: fn -> Routex.Path.split(@path)	 end
  # }, time: 10
  # 						)
end

# Name                    ips        average  deviation         median         99th %
# match_pattern       60.42 K       16.55 μs   ±117.67%       12.37 μs       49.92 μs
# match_map           43.72 K       22.87 μs   ±162.48%       17.27 μs       72.76 μs

# Comparison:
# match_pattern       60.42 K
# match_map           43.72 K - 1.38x slower +6.32 μs

# Memory usage statistics:

# Name             Memory usage
# match_pattern         2.80 KB
# match_map             4.09 KB - 1.46x memory usage +1.30 KB

# NOTE TO SELF; MatchMap
# 1. should have a matchable pattern for function heads (currently :dynamic breaks it) 
# 2. dynamic should be recomposable into a route pattern given a base route pattern (so we do need :dynamic for ordering?)
# 3. prefer easy inspection

# ~p"/users/%{user}/edit?q=some#fragment" should match "/users/:id/edit"
# ~p"/users/12/edit?q=some#fragment" should match "/users/:id/edit"
# ["/users/", ":id", "/edit", "?q=some#fragment"] should match "/users/:id/edit"
# ["/users/", ast, "/edit"] should match "/users/:id/edit"

# Issues with MatchMap
# Runtime URL's have a different length and no dynamics. So mixing runtime and compile time is impossible

# Issues with pattern_match
# It loses domain information and is either too loose or too strict (query, fragments)

# How to match....
# "http://domain.com:4000/some/product/12/?foo#bar"?

# We can create matches per type!
# %Route{}
# binary (aka: url)

:verb
:hosts
:path
