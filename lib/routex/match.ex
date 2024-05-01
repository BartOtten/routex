

defmodule Routex.Match do
  @moduledoc """
  hosts: the list of request hosts or host prefixes
  """

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
  def new(input) when is_binary(input), do:
    input |> URI.parse() |> new()

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
      hosts: route.hosts,
      segments: split_path(route.path) |> unify_segments(),
      trailing_slash?: route.trailing_slash?
    )
  end

  def new({:<<>>, _meta, args} = input) do
    segments =
      Enum.flat_map(args, fn
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
    match(segments: segments, trailing_slash?: trailing_slash?)
  end



  @doc """
  Creates a function named `name` which one argument which pattern matches
  a specific Match record pattern.
  """
	def to_func(match_pattern, name, other_args \\ [], body)
	
  def to_func(match_pattern, name, other_args, body) when is_tuple(match_pattern) do

		other_args =

			Enum.map(other_args, fn
				{arg, value} ->
			quote do
				unquote(Macro.var(arg, __ENV__.module )) = (unquote(value))
			end

				arg when is_atom(arg) -> quote do
																	unquote(Macro.var(arg, __ENV__.module )) 
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
    to_func(to_pattern(route), name, other_args, body)
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
		match( segments: segments, query: query, fragment: fragment) = record
		
		struct(URI, %{path: Enum.join(["" |  segments], @path_seperator), query: query, fragment: fragment}) |> to_string()	
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
#end
