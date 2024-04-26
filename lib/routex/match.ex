defmodule Match do
  @moduledoc """
  hosts: the list of request hosts or host prefixes
  """
  require Record

  Record.defrecord(:match,
    hosts: [],
    segments: [],
    query: nil,
    fragment: nil,
    trailing_slash?: false,
    exprs: []
  )

  @path_seperator "/"
  @query_separator "?"
  @fragment_separator "#"
  @interpolated [?:, ?*]

  def split_path(input) when is_binary(input), do: String.split(input, @path_seperator)
  def trailing?(input) when is_binary(input), do: String.ends_with?(input, @path_seperator)
  def trailing?(_), do: false

  def uniform_segments(segments), do: Enum.reject(segments, &(&1 == ""))

  def new(input) when is_binary(input) do
    uri = URI.parse(input)
    trailing_slash? = trailing?(uri.path)
    segments = split_path(uri.path) |> uniform_segments()

    match(
      hosts: [uri.host],
      segments: segments,
      query: uri.query,
      fragment: uri.fragment,
      trailing_slash?: trailing_slash?
    )
  end

  def new(%Phoenix.Router.Route{} = input) do
    segments = split_path(input.path) |> uniform_segments()

    exprs =
      segments
      |> Enum.with_index()
      |> Enum.filter(fn {<<x>> <> _, _idx} -> x in @interpolated end)
      |> Enum.into(%{})

    match(
      hosts: input.hosts,
      segments: segments,
      exprs: exprs,
      trailing_slash?: input.trailing_slash?
    )
  end

  def new({:<<>>, _meta, args} = input) do
    segments =
      Enum.flat_map(args, fn
        path when is_binary(path) -> split_path(path)
        arg -> [arg]
      end)
      |> uniform_segments()
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

	def to_func(module, name, func, %Phoenix.Router.Route{} = route) do
		match = to_match(module, name, func, route)
		quote do
			def unquote(name)(unquote(match)) do
				unquote(func)
			end
		end
	end

  def to_match(module, name, func, %Phoenix.Router.Route{} = route) do
    record = new(route)

		segments_ast = Enum.map(match(record, :segments), fn
    ":" <> name -> quote do: unquote(name |> String.to_atom() |> Macro.var(module))
    other -> other
    end)
		
		exprs_ast = Macro.var(:exprs, module)
		hosts_ast = Macro.var(:hosts, module)
		query_ast = Macro.var(:query, module)
		fragment_ast = Macro.var(:fragment, module)
		trailing_ast = match(record, :trailing_slash?)

		#	record_ast = match(record, segments: segments_ast, exprs: exprs_ast)
		
					quote do		{:match,
							 unquote(hosts_ast),
							 unquote(segments_ast),
							 unquote(query_ast),
							 unquote(fragment_ast),
							 unquote(trailing_ast),
											 unquote(exprs_ast)}
						end
		end


  # COMPILE TIME
  # sigil -> find route -> know arg names -> bind ast to names -> rewrite url

  # we need:
  # a map with routes and a way to map a sigil to a route. Or...matchable function which return a route
end

defmodule Example do
  require Match

  @route %Phoenix.Router.Route{
    verb: nil,
    line: nil,
    kind: nil,
    path: "/:country/products/:id/edit",
    hosts: [],
    plug: nil,
    plug_opts: nil,
    helper: nil,
    private: nil,
    pipe_through: nil,
    assigns: nil,
    metadata: nil,
    trailing_slash?: false,
    warn_on_verify?: nil
   }

	 @route2 %Phoenix.Router.Route{
    verb: nil,
    line: nil,
    kind: nil,
    path: "/:country/:id/edit/producto",
    hosts: [],
    plug: nil,
    plug_opts: nil,
    helper: nil,
    private: nil,
    pipe_through: nil,
    assigns: nil,
    metadata: nil,
    trailing_slash?: false,
    warn_on_verify?: nil
		}

	 @route3 %Phoenix.Router.Route{
    verb: nil,
    line: nil,
    kind: nil,
    path: "/some/other/:id/ed**/:country/produ**",
    hosts: [],
    plug: nil,
    plug_opts: nil,
    helper: nil,
    private: nil,
    pipe_through: nil,
    assigns: nil,
    metadata: nil,
    trailing_slash?: false,
    warn_on_verify?: nil
  }

	def compile() do
		var_module = __MODULE__
		
		recompose_ast = quote do: unquote(Match.to_match(var_module, :match, nil, @route3))
		route_definition_ast = quote do: unquote(@route |> Macro.escape())
		
		ast = [
			Match.to_func(var_module, :recompose, recompose_ast, @route),
			Match.to_func(var_module, :route, route_definition_ast, @route) 
]
		Module.create(Foo, ast, __ENV__)
	end
end
