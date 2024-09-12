defmodule Routex.Match do
  @moduledoc """
	Match records are an essential part of Routex. They are used to match
	compile time routes with runtime routes, while also binding values with
	the possibility to bind values.

	** Examples

	iex > path = "/posts/1?foo=bar#top"
	    > route = %Phoenix.Router.Route{path: "/posts/:id"}
	    > sigil = {:<<>>, [], ["/products/", {:"::", [], [{{:., [], [Kernel, :to_string]}, [from_interpolation: true], [{:id, [], Elixir}]}, {:binary, [], Elixir}]}]}

	iex> Routex.Match.new(path)
	{:match, [nil], ["posts", "1"], "foo=bar", "top", false}

	iex> Routex.Match.new(route)
  {:match, [], ["posts", ":id"], nil, nil, false}

	iex> Routex.Match.new(sigil)
	{:match, [], ["posts", {:"::", [], [{{:., [], [Kernel, :to_string]}, [from_interpolation: true], [{:id, [], Elixir}]}, {:binary, [], Elixir}]}], nil, nil, false}


	The unified Match records can be converted to patterns, to be used in pattern matching. As the patterns also bind values,the can be used for input and output.


	iex > "/original/:arg1/:arg2" |> Routex.Match.new() |> Routex.Match.to_pattern()
  {:{}, [], [:match, {:hosts, [], Routex.Match}, ["original", {:arg1, [], Routex.Match}, {:arg2, [], Routex.Match}], {:query, [], Routex.Match}, {:fragment, [], Routex.Match}, false]}

	"iex> /recomposed/:arg2/:arg1" |> Routex.Match.new() |> Routex.Match.to_pattern()
 {:{}, [], [:match, {:hosts, [], Routex.Match}, ["recomposed", {:arg2, [], Routex.Match}, {:arg1, [], Routex.Match}], {:query, [], Routex.Match}, {:fragment, [], Routex.Match}, false]}


iex> "/original/segment_1/segment_2" |> Routex.Match.new() |> Routex.Match.to_pattern()
{:{}, [], [:match, {:hosts, [], Routex.Match}, ["original", "segment_1", "segment_2"], {:query, [], Routex.Match}, {:fragment, [], Routex.Match}, false]}





	
  hosts: the list of request hosts or host prefixes
  """


	# TODO: Make `match?` also match AST with placeholders like `:id`

  @path_seperator "/"
  @query_separator "?"
  @fragment_separator "#"
  @interpolated [?:, ?*]

  require Record

  Record.defrecord(:match,
    hosts: [],
    segments: [],
    query: nil,
    fragment: nil,
    trailing_slash?: false
  )

  @doc """
  Converts a binary URL, `Phoenix.Router.Route` or sigil into a Match record.
  """
  def new(input) when is_binary(input), do: input |> URI.parse() |> new()
	def new(input) when is_list(input), do: match(segments: unify_segments(input))

  def new(%URI{} = uri) do
    match(
      hosts: [uri.host],
      segments: split_path(uri.path) |> unify_segments(),
      query: uri.query,
      fragment: uri.fragment,
      trailing_slash?: trailing?(uri.path)
    )
  end

  def new(%Phoenix.Router.Route{} = route) do
    match(
      hosts: route.hosts || [],
      segments: split_path(route.path) |> unify_segments(),
      trailing_slash?: route.trailing_slash? || false
    )
  end

  def new({_func, _meta1, [ast, []]}), do: new(ast)

  def new({:<<>>, _meta, args} = input) do
    segments =
      Enum.map(args, fn
        segment when is_binary(segment) ->
          uri = URI.parse(segment)
          [uri.path]

        segment ->
          [segment]
      end)
      |> List.flatten()

    query =
      Enum.find_value(args, fn
        segment when is_binary(segment) ->
          uri = URI.parse(segment)
          uri.query

        _segment ->
          false
      end)

    fragment =
      Enum.find_value(args, fn
        segment when is_binary(segment) ->
          uri = URI.parse(segment)
          uri.fragment

        segment ->
          false
      end)

    segments =
      Enum.flat_map(segments, fn
        path when is_binary(path) -> split_path(path)
        arg -> [arg]
      end)
      |> unify_segments()
      |> Enum.reduce_while([], fn
        x, acc when is_binary(x) ->
          if String.ends_with?(x, @query_separator) do
            {:halt, [String.trim(x, @query_separator) | acc]}
          else
            {:cont, [x | acc]}
          end

        x, acc ->
          {:cont, [x | acc]}
      end)
      |> Enum.reverse()

    trailing_slash? = List.last(segments) |> trailing?()

    match(segments: segments, query: query, fragment: fragment, trailing_slash?: trailing_slash?)
  end

  @doc """
  Creates a function named `name` which the first argument matching
  a Match record pattern. Other arguments can be given with either a
  catch all or a pattern.

  *Example*
     iex> "/some/path"
        >  |> Match.new()
        >  |> Match.to_func(:my_func, [pattern_arg: "fixed", :catchall_arg], quote(do: :ok))
  """
  def to_func(match_pattern, name, other_args \\ [], body)

  def to_func(record, name, other_args, body) when is_tuple(record) do
    match_pattern = to_pattern(record)

    other_args =
      Enum.map(other_args, fn
        {arg, value} ->
          quote do
            unquote(Macro.var(arg, __ENV__.module)) = unquote(value)
          end

        arg when is_atom(arg) ->
          quote do
            unquote(Macro.var(arg, __ENV__.module))
          end
      end)

    args = [match_pattern] ++ other_args

    quote do
      def unquote(name)(unquote_splicing(args)) do
        unquote(body)
      end
    end
  end

  def to_func(%Phoenix.Router.Route{} = route, name, other_args, body) do
    to_func(new(route), name, other_args, body)
  end

  @doc """
  Returns a match pattern for given `Match` record or `Phoenix.Router.Route`. The pattern can be used either as function argument or in a function body.
  """

  def to_pattern(%Phoenix.Router.Route{} = route),
    do: route |> new() |> to_pattern()

  def to_pattern(record) when is_tuple(record) do
    segments_ast =
      Enum.map(match(record, :segments), fn
        ":" <> name -> quote do: unquote(name |> String.to_atom() |> Macro.var(__MODULE__))
        other -> other
      end)

    hosts_ast = Macro.var(:hosts, __MODULE__)
    query_ast = Macro.var(:query, __MODULE__)
    fragment_ast = Macro.var(:fragment, __MODULE__)
    trailing_ast = match(record, :trailing_slash?)

    # 	record_ast = match(record, segments: segments_ast, exprs: exprs_ast)

    quote do
      {:match, unquote(hosts_ast), unquote(segments_ast), unquote(query_ast),
       unquote(fragment_ast), unquote(trailing_ast)}
    end
  end

  defp split_path(input) when is_binary(input),
    do: String.split(input, @path_seperator)

  defp trailing?(input) when is_binary(input),
    do: String.ends_with?(input, @path_seperator)

  defp trailing?(_),
    do: false

  defp unify_segments(segments),
    do: Enum.reject(segments, &(&1 == ""))

  @doc """
   A non conflicting function mimicking `to_string/1`
  """

  def to_binary(record) do
    match(segments: segments, query: query, fragment: fragment) = record

    struct(URI, %{
      path: Enum.join(["" | segments], @path_seperator),
      query: query,
      fragment: fragment
    })
    |> to_string()
  end

  def match?(r1, r2) do


		#route_list & AST
    #route_list & static

		## NEEDS TO LOSELY MATCH TOO
	# 	{:match, [nil], ["products", ":id", "edit"], nil, nil, false}
		
 # 		{:match, [],
 # [
 #   "products",
 #   {:"::", [line: 21],
 #    [
 #      {{:., [line: 21], [Kernel, :to_string]},
 #       [from_interpolation: true, line: 21], [{:product, [line: 21], nil}]},
 #      {:binary, [line: 21], nil}
 #    ]},
 #   "edit",
 #   "?",
 #   {:"::", [line: 21],
 #    [
 #      {{:., [line: 21], [Kernel, :to_string]},
 #       [from_interpolation: true, line: 21],
 #       [{:%{}, [line: 21], [foo: "bar"]}]},
 #      {:binary, [line: 21], nil}
 #    ]}
 # ], nil, nil, false}




		# IO.puts("#{inspect(r1)} vs #{inspect(r2)}")
		s1 = match(r1, :segments) 
    s2 = match(r2, :segments)

		{s1, _} = Enum.split_while(s1, fn x -> x != "?" || !String.starts_with?(x,"?") end)
		{s2, _} = Enum.split_while(s2, fn x -> x != "?" || !String.starts_with?(x,"?") end)

	reduc =  fn
		x when is_binary(x) -> Path.split(x)
		x -> x
	end

		s1=Enum.map(s1, &reduc.(&1)) |> List.flatten() #|> dbg
			s2=Enum.map(s2, &reduc.(&1)) |> List.flatten() #|> dbg
		

		si1 = s1 |> Enum.with_index(fn x,y -> {y,x} end)
		si2 = s2 |> Enum.with_index(fn x,y -> {y,x} end)  |> Map.new()

		
		# IO.inspect(si1, label: :Si1)
		# IO.inspect(si2, label: :Si2)
		
is_match = length(s1) == length(s2) &&
		
	Enum.all?(si1, fn
	{_idx, ":" <> seg} -> true
	{_idx, "*"} -> true
	{idx, other} -> si2[idx] == other	
	end)

		is_match && IO.puts("MATCH: #{inspect(s2)} MATCHES PATTERN OF #{inspect(s1)}")

		is_match
		# |> dbg
		
		
    #(match(r1, :segments) == match(r2, :segments)) |> dbg
  end
end

# defmodule Example do
#   require Match

#   @route %Phoenix.Router.Route{
#     verb: nil,
#     line: nil,
#     kind: nil,
#     path: "/:country/products/:id/edit",
#     hosts: [],
#     plug: nil,
#     plug_opts: nil,
#     helper: nil,
#     private: nil,
#     pipe_through: nil,
#     assigns: nil,
#     metadata: nil,
#     trailing_slash?: false,
#     warn_on_verify?: nil
#   }

#   @route2 %Phoenix.Router.Route{
#     verb: nil,
#     line: nil,
#     kind: nil,
#     path: "/:country/:id/edit/producto",
#     hosts: [],
#     plug: nil,
#     plug_opts: nil,
#     helper: nil,
#     private: nil,
#     pipe_through: nil,
#     assigns: nil,
#     metadata: nil,
#     trailing_slash?: false,
#     warn_on_verify?: nil
#   }

#   @route3 %Phoenix.Router.Route{
#     verb: nil,
#     line: nil,
#     kind: nil,
#     path: "/some/other/:id/ed**/:country/produ**",
#     hosts: [],
#     plug: nil,
#     plug_opts: nil,
#     helper: nil,
#     private: nil,
#     pipe_through: nil,
#     assigns: nil,
#     metadata: nil,
#     trailing_slash?: false,
#     warn_on_verify?: nil
#   }

#   def compile() do
#     recompose_ast = quote do: unquote(Match.to_pattern(@route3))
#     route_definition_ast = quote do: unquote(@route |> Macro.escape())

#     ast = [
#       Match.to_func(@route, :recompose, recompose_ast),
#       quote do
#         def recompose(input) when is_tuple(input), do: {:not_found, input}
#         def recompose(input), do: {:error, :input_no_match_record}
#       end,
#       Match.to_func(@route, :route, route_definition_ast),
#       quote do
#         def route(input) when is_tuple(input), do: {:not_found, input}
#         def route(input), do: {:error, :input_no_match_record}
#       end
#     ]

#     Routex.Dev.inspect_ast(ast)

#     Module.create(Foo, ast, __ENV__)
#   end
# end
