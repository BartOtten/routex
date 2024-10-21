defmodule Routex.Matchable do
  @moduledoc """
  Matchables are an essential part of Routex. They are used to match run time
  routes with compile time routes.

  This module provides functions to create Matchables, convert them to match
  pattern AST as well as function heads AST and to check if the routing values
  of two Matchable records match.
  """

  @path_separator "/"
  @query_separator "?"
  @ast_placeholder "_RTX_"

  require Record
  import Record

  defrecord(:matchable,
    hosts: [],
    path: [],
    query: [],
    fragment: []
  )

  defguardp is_ast(input) when is_tuple(input) and tuple_size(input) == 3

  @doc """
  Converts a binary URL, `Phoenix.Router.Route` or (sigil) AST argument into a Matchable record.

  ** Examples

  iex> path = "/posts/1?foo=bar#top"
     > route = %Phoenix.Router.Route{path: "/posts/:id"}
     > ast = {:<<>>, [], ["/products/", {:"::", [], [{{:., [], [Kernel, :to_string]}, [from_interpolation: true], [{:id, [], Elixir}]}, {:binary, [], Elixir}]}]}

  iex> path_match = Routex.Matchable.new(path)
  {:matchable, [nil], ["posts", "1"], "foo=bar", "top", false}

  iex> route_match = Routex.Matchable.new(route)
  {:matchable, [], ["posts", ":id"], nil, nil, false}

  iex> ast_match = Routex.Matchable.new(ast)
  {:matchable, [], ["posts", {:"::", [], [{{:., [], [Kernel, :to_string]}, [from_interpolation: true], [{:id, [], Elixir}]}, {:binary, [], Elixir}]}], nil, nil, false}

  """
  def new(input) when is_binary(input) do
    # Mimmicks the regex from URI.parse/1 but does not consider a hash (`#`) start of a
    # fragment when directly followed by a curly bracket (`{`) as the combination `#{` is used
    # for string interpolation. Note that the characters `{` and `}` are not valid in URIs
    # (see RFC 3986) so we can assume any `#{` is meant as interpolation start.

    # A comparison to the regex in `URI.parse/1` using a binary URL -without interpolation syntax
    # as it would cause URI/parse to 'early exit'): "https://user@foo.com:80/bar/product?q=baz#top"

    # uri   564.60 K | 640 B
    # match 485.64 K | 472 B

    # 1.16x slower (+0.29 μs) | 0.74x memory usage (-168 B)

    regex =
      ~r{^(([a-z][a-z0-9\+\-\.]*):)?(//([^/?#]*))?((?:(?:[^#?]*):?\#{)*(?:[^?#]*))(\?([^#](*:?\#{)[^#]*))?(#(.*))?}i

    parts = Regex.run(regex, input)

    destructure [
                  _full,
                  # 1
                  _scheme_with_colon,
                  # 2
                  _scheme,
                  # 3
                  _authority_with_slashes,
                  # 4
                  authority,
                  # 5
                  path,
                  # 6
                  query_with_question_mark,
                  # 7
                  _query,
                  # 8
                  fragment_with_hash,
                  # 9
                  _fragment
                ],
                parts

    authority = nillify(authority)
    path = nillify(path)
    query_with_question_mark = nillify(query_with_question_mark)
    fragment_with_hash = nillify(fragment_with_hash)

    matchable(
      hosts: authority && List.wrap(authority),
      path: path && split_path(path),
      query: query_with_question_mark && List.wrap(query_with_question_mark),
      fragment: fragment_with_hash && List.wrap(fragment_with_hash)
    )
  end

  def new(%Phoenix.Router.Route{} = route) do
    matchable(
      hosts: route.hosts || [],
      path: split_path(route.path)
    )
  end

  def new({:<<>>, _meta, path_segments}), do: new(path_segments)

  def new(path_segments) when is_list(path_segments) do
    {binary_path_segments, dyns} = path_segments_to_binaries(path_segments)

    uri = binary_path_segments |> Enum.join() |> URI.parse() |> Map.from_struct()

    map =
      for type <- [:path, :query, :fragment], into: %{} do
        v =
          case value = uri[type] do
            nil ->
              []

            _ ->
              value
              |> split_path()
              |> placeholders_to_ast(dyns)
          end

        {type, v}
      end

    matchable(
      path: map.path,
      query: (map.query != [] && ["?" | map.query]) || [],
      fragment: (map.fragment != [] && ["#" | map.fragment]) || []
    )
  end

  defp nillify(""), do: []
  defp nillify(nil), do: []
  defp nillify(other), do: other

  def placeholders_to_ast(path, dyns) do
    codepoint_to_integer = fn codepoint -> <<codepoint>> |> to_string |> String.to_integer() end

    Enum.flat_map(path, fn
      <<@ast_placeholder, codepoint::utf8>> ->
        idx = codepoint_to_integer.(codepoint)
        [Enum.at(dyns, idx)]

      <<@ast_placeholder, codepoint::utf8, rest::binary>> ->
        idx = codepoint_to_integer.(codepoint)
        [Enum.at(dyns, idx) | placeholders_to_ast([rest], dyns)]

      "" ->
        []

      o when is_binary(o) ->
        path = String.split(o, ~r"_RTX_\d", include_captures: true)

        if length(path) == 1 do
          path
        else
          placeholders_to_ast(path, dyns)
        end
    end)
  end

  defp path_segments_to_binaries(path) do
    {path, dyns} =
      path
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

    {path |> Enum.reverse(), dyns |> Enum.reverse()}
  end

  defp seg_to_binary(nil), do: nil
  defp seg_to_binary(segment) when is_integer(segment), do: to_string(segment)
  defp seg_to_binary(segment) when is_atom(segment), do: ":" <> to_string(segment)
  defp seg_to_binary(segment) when is_ast(segment), do: @ast_placeholder
  defp seg_to_binary(segment) when is_binary(segment), do: segment

  @doc """
  Creates a function named `name` which the first argument matching
  a Matchable record pattern. Other arguments can be given with either a
  catch all or a pattern.

  The Matchable pattern is bound to `pattern`

  *Example*
     iex> "/some/path"
        >  |> Matchable.new()
        >  |> Matchable.to_func(:my_func, [pattern_arg: "fixed", :catchall_arg], quote(do: :ok))
  """
  def to_func(match_pattern, name, other_args \\ [], body)

  def to_func(record, name, other_args, body) when is_tuple(record) do
    match_pattern =
      quote do
        pattern = unquote(to_pattern(record))
      end

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
  Returns a match pattern for given `Matchable` record or `Phoenix.Router.Route`. The pattern can be used either as
  function argument or in a function body. As the patterns bind values, they can be used to convert input from
  one pattern to another.


  iex> "/original/:arg1/:arg2" |> Routex.Matchable.new() |> Routex.Matchable.to_pattern()
  {:{}, [], [:matchable, {:hosts, [], Routex.Matchable}, ["original", {:arg1, [], Routex.Matchable}, {:arg2, [], Routex.Matchable}], {:query, [], Routex.Matchable}, {:fragment, [], Routex.Matchable}, false]}

  "iex> /recomposed/:arg2/:arg1" |> Routex.Matchable.new() |> Routex.Matchable.to_pattern()
  {:{}, [], [:matchable, {:hosts, [], Routex.Matchable}, ["recomposed", {:arg2, [], Routex.Matchable}, {:arg1, [], Routex.Matchable}], {:query, [], Routex.Matchable}, {:fragment, [], Routex.Matchable}, false]}


  iex> "/original/segment_1/segment_2" |> Routex.Matchable.new() |> Routex.Matchable.to_pattern()
  {:{}, [], [:matchable, {:hosts, [], Routex.Matchable}, ["original", "segment_1", "segment_2"], {:query, [], Routex.Matchable}, {:fragment, [], Routex.Matchable}, false]}
  """

  def to_pattern(%Phoenix.Router.Route{} = route),
    do: route |> new() |> to_pattern()

  def to_pattern(record) when is_tuple(record) do
    path_ast =
      Enum.map(matchable(record, :path), fn
        ":" <> name -> quote do: unquote(name |> String.to_atom() |> Macro.var(__MODULE__))
        other -> other
      end)

    hosts_ast = Macro.var(:hosts, __MODULE__)
    query_ast = Macro.var(:query, __MODULE__)
    fragment_ast = Macro.var(:fragment, __MODULE__)

    quote do
      {:matchable, unquote(hosts_ast), unquote(path_ast), unquote(query_ast),
       unquote(fragment_ast)}
    end
  end

  defp split_path(input) when is_nil(input), do: []

  defp split_path(input) when is_binary(input) do
    String.split(input, ~r"#{@path_separator}", include_captures: true)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
   A non conflicting function mimicking `to_string/1`
  """

  def to_binary(record) do
    matchable(path: path, query: query, fragment: fragment) = record
    Enum.join([path, query, fragment])
  end

  def to_ast_segments(record) do
    s = matchable(record, :path) || []
    q = matchable(record, :query) || []
    f = matchable(record, :fragment) || []

    (s ++ q ++ f)
    |> Enum.reduce([], fn
      segment, [h | t] when is_binary(segment) and is_binary(h) -> [h <> segment | t]
      segment, acc -> [segment | acc]
    end)
    |> Enum.reverse()
  end

  @doc """
  Returns whether two Matchable records match on their route defining properties. The first argument
  supports string interpolation syntax (e.g ":param" and "*") forming wildcards.

  ** Example **

  iex> route_record = %Phoenix.Router.Route{path: "/posts/:id"} |> Routex.Matchable.new()
     > matching_record = "/posts/1/foo=bar#top" |> Routex.Matchable.new()
     > failing_record = "/products/1/foo=bar#op" |> Routex.Matchable.new()

  iex> match?(route_record, matching_record)
  true
  iex match?(route_record, failing_record)
  false
  """

  def match?(r1, r2) when is_record(r1, :matchable) and is_record(r2, :matchable) do
    s1 = matchable(r1, :path)
    s2 = matchable(r2, :path)

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

  def match?(r1, r2) when not is_record(r1, :matchable), do: __MODULE__.match?(new(r1), r2)
  def match?(r1, r2) when not is_record(r2, :matchable), do: __MODULE__.match?(r1, new(r2))
end
