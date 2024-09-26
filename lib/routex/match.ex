defmodule Routex.Match do
  @moduledoc """
   Match records are an essential part of Routex. They are used to match
   compile time routes with runtime routes. This module procides functions
  to create Match records, convert them to match pattern AST as well as
  function heads AST and to check if the routing values of two Match records
  match.
  """

  # TODO: Make `match?` also match AST with placeholders like `:id`

  @path_seperator "/"
  @query_separator "?"
  @ast_placeholder "_RTX_"

  require Record

  Record.defrecord(:match,
    hosts: [],
    segments: [],
    query: nil,
    fragment: nil,
    trailing_slash?: false
  )

  defguardp is_ast(input) when is_tuple(input) and tuple_size(input) == 3

  @doc """
  Converts a binary URL, `Phoenix.Router.Route` or sigil into a Match record.

  ** Examples

  iex> path = "/posts/1?foo=bar#top"
     > route = %Phoenix.Router.Route{path: "/posts/:id"}
     > sigil = {:<<>>, [], ["/products/", {:"::", [], [{{:., [], [Kernel, :to_string]}, [from_interpolation: true], [{:id, [], Elixir}]}, {:binary, [], Elixir}]}]}

  iex> path_match = Routex.Match.new(path)
  {:match, [nil], ["posts", "1"], "foo=bar", "top", false}

  iex> route_match = Routex.Match.new(route)
  {:match, [], ["posts", ":id"], nil, nil, false}

  iex> ast_match = Routex.Match.new(sigil)
  {:match, [], ["posts", {:"::", [], [{{:., [], [Kernel, :to_string]}, [from_interpolation: true], [{:id, [], Elixir}]}, {:binary, [], Elixir}]}], nil, nil, false}

  """
  def new(input) when is_binary(input), do: input |> URI.parse() |> new()
  def new(input) when is_list(input), do: match(segments: unify_segments(input))

  def new(%URI{} = uri) do
    match(
      hosts: (uri.host && [uri.host]) || [],
      segments: split_path(uri.path) |> unify_segments(),
      query: uri.query && [uri.query],
      fragment: uri.fragment && [uri.fragment],
      trailing_slash?: trailing?(uri.path)
    )
  end

  def new(%Phoenix.Router.Route{} = route) do
    match(
      hosts: route.hosts || [],
      segments: split_path(route.path) |> unify_segments(),
      trailing_slash?: route.trailing_slash? || route.path == "/" || false
    )
  end

  def new({_func, _meta1, [ast, []]}), do: new(ast)

  def new({:<<>>, _meta, segments}) do
    {segs, dyns} =
      segments
      |> segs_to_binaries()

    uri = segs |> Enum.join() |> URI.parse() |> Map.from_struct()
    trailing_slash? = trailing?(uri.path)

    map =
      for type <- [:path, :query, :fragment], into: %{} do
        v =
          case value = uri[type] do
            nil ->
              nil

            _ ->
              value
              |> String.split("/")
              |> placeholders_to_ast(dyns)
          end

        {type, v}
      end

    match(
      segments: map.path,
      query: map.query,
      fragment: map.fragment,
      trailing_slash?: trailing_slash?
    )
  end

	def placeholders_to_ast(segments, dyns) do
		 codepoint_to_integer = fn codepoint -> <<codepoint>> |> to_string |> String.to_integer() end
	Enum.flat_map(segments, fn
                <<@ast_placeholder, codepoint::utf8>> ->
                  idx = codepoint_to_integer.(codepoint)
                  [Enum.at(dyns, idx)]

                <<@ast_placeholder, codepoint::utf8, rest::binary>> ->
                  idx = codepoint_to_integer.(codepoint)
                  [Enum.at(dyns, idx), placeholders_to_ast([rest], dyns)]

                "" ->
                  []

                o when is_binary(o) ->
									segments = String.split(o, ~r"_RTX_\d", include_captures: true)

									if length(segments) == 1 do
										segments
											else
												placeholders_to_ast(segments, dyns)
												end               
  end)
		end

  defp segs_to_binaries(segments) do
    {segs, dyns} =
      segments
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce({[], []}, fn
        seg, {acc, dyns} when is_ast(seg) ->
          count = length(dyns)
          dyns = [seg | dyns]
          str = seg_to_binary(seg) <> to_string(count)

          {[str | acc], dyns}

        seg, {acc, dyns} ->
          {[seg_to_binary(seg) | acc], dyns}
      end)

    {segs |> Enum.reverse(), dyns |> Enum.reverse()}
  end

  defp seg_to_binary(nil), do: nil
  defp seg_to_binary(segment) when is_integer(segment), do: to_string(segment)
  defp seg_to_binary(segment) when is_atom(segment), do: ":" <> to_string(segment)
  defp seg_to_binary(segment) when is_ast(segment), do: @ast_placeholder
  defp seg_to_binary(segment) when is_binary(segment), do: segment

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
  Returns a match pattern for given `Match` record or `Phoenix.Router.Route`. The pattern can be used either as
  function argument or in a function body. As the patterns bind values, they can be used to convert input from
  one pattern to another.


  iex> "/original/:arg1/:arg2" |> Routex.Match.new() |> Routex.Match.to_pattern()
  {:{}, [], [:match, {:hosts, [], Routex.Match}, ["original", {:arg1, [], Routex.Match}, {:arg2, [], Routex.Match}], {:query, [], Routex.Match}, {:fragment, [], Routex.Match}, false]}

  "iex> /recomposed/:arg2/:arg1" |> Routex.Match.new() |> Routex.Match.to_pattern()
  {:{}, [], [:match, {:hosts, [], Routex.Match}, ["recomposed", {:arg2, [], Routex.Match}, {:arg1, [], Routex.Match}], {:query, [], Routex.Match}, {:fragment, [], Routex.Match}, false]}


  iex> "/original/segment_1/segment_2" |> Routex.Match.new() |> Routex.Match.to_pattern()
  {:{}, [], [:match, {:hosts, [], Routex.Match}, ["original", "segment_1", "segment_2"], {:query, [], Routex.Match}, {:fragment, [], Routex.Match}, false]}
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

    # the trailing slash is not used for matching purposes in Phoenix.
		# match(record, :trailing_slash?)
		trailing_ast = Macro.var(:trailing_slash?, __MODULE__)

    quote do
      {:match, unquote(hosts_ast), unquote(segments_ast), unquote(query_ast),
       unquote(fragment_ast), unquote(trailing_ast)}
    end
  end

  defp split_path(input) when is_nil(input), do: []

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

  def to_sigil_segments(record) do
    s = match(record, :segments)
    q = match(record, :query)
    f = match(record, :fragment)
		t = match(record, :trailing_slash?)

    new_segments =
      s
      |> Enum.reduce([], fn
        segment, [] = _acc -> ["/" <> segment | []]
        segment, [h | t] when is_binary(segment) and is_binary(h) -> [h <> "/" <> segment | t]
        segment, acc when is_binary(segment) -> ["/" <> segment | acc]
        segment, acc -> [segment, "/" | acc]
      end)
      |> List.flatten()

		# support trailing slashes
		new_segments = t && ["/" | new_segments] || new_segments

		new_segments =
      case new_segments do
        [] -> ["/"]
        other -> other |> Enum.reject(&is_nil/1) |> Enum.reverse()
      end

    # hack to support "/users/login?_action=updated
    new_segments =
      case q do
        nil -> new_segments
        [h | t] when is_binary(h) -> (new_segments ++ ["?" <> h | t]) |> List.flatten()
        q -> (new_segments ++ ["?" | q]) |> List.flatten()
      end

    new_segments = (f && (new_segments ++ ["#", f]) |> List.flatten()) || new_segments

    List.wrap(new_segments)
  end

  @doc """
  Returns whether two Match records match on their route defining properties. The first argument
  supports string interpolation syntax (e.g ":param" and "*") forming wildcards.

  ** Example **

  iex> route_record = %Phoenix.Router.Route{path: "/posts/:id"} |> Routex.Match.new()
     > matching_record = "/posts/1/foo=bar#top" |> Routex.Match.new()
     > failing_record = "/products/1/foo=bar#op" |> Routex.Match.new()

  iex> match?(route_record, matching_record)
  true
  iex match?(route_record, failing_record)
  false
  """
  def match?(r1, r2) do
    s1 = match(r1, :segments)
    s2 = match(r2, :segments)

    {s1, _} =
      Enum.split_while(s1, fn x ->
        x != @query_separator || !String.starts_with?(x, @query_separator)
      end)

    {s2, _} =
      Enum.split_while(s2, fn x ->
        x != @query_separator || !String.starts_with?(x, @query_separator)
      end)

    maybe_split_fn = fn
      x when is_binary(x) -> Path.split(x)
      x -> x
    end

    s1 = Enum.map(s1, &maybe_split_fn.(&1)) |> List.flatten()
    s2 = Enum.map(s2, &maybe_split_fn.(&1)) |> List.flatten()

    is_match =
      length(s1) == length(s2) &&
        Enum.zip(s1, s2)
        |> Enum.all?(fn
          {":" <> _, _} -> true
          {"*", _} -> true
          {equal, equal} -> true
          _not_equal -> false
        end)

    is_match
  end
end
