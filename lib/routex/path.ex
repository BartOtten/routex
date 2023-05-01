# credo:disable-for-this-file
defmodule Routex.Path do
  @moduledoc """
  Provides functions that work with both a binary path and a
  list of segments; unless explicitly stated otherwise.
  """
  require Integer
  alias Plug.Router.Utils

  @interpolate ":"
  @catch_all "*"
  @query_separator "?"
  @fragment_separator "#"
  @path_separator "/"
  @root @path_separator

  @doc """
  Joins a (nested) list of path segments into a binary path..
  """
  def join([]), do: @root

  def join(segments) do
    segments
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn
      segment when is_integer(segment) -> to_string(segment)
      segment when is_atom(segment) -> ":" <> to_string(segment)
      other -> other
    end)
    |> Path.join()
    |> String.replace_trailing(@query_separator, "")
    |> String.replace(@path_separator <> @query_separator, @query_separator)
    |> String.replace(@path_separator <> @fragment_separator, @fragment_separator)
    |> Path.absname("")
  end

  @doc """
  Converts the `input` to a list of segments. It's a convenience wrapper for
  Plug.Router.Utils.split/1 to also handle nil value and segment lists.
  Additionally queries will always have their own segment.

  **Examples**
      iex> split(nil)
      []
      iex> split("/foo/bar/?baz=qux")
      ["foo", "bar", "?baz=qux"]
      iex> split(["/foo/bar", "/baz"])
      ["foo", "bar", "baz"]
  """

  def split(nil), do: []

  def split(input) when is_list(input) do
    for path <- input do
      split(path)
    end
    |> List.flatten()
  end

  def split(input) when is_binary(input) do
    url = URI.parse(input)
    path = (url.path || "") |> Utils.split()

    p1 =
      if url.query do
        [path, @query_separator <> url.query] |> List.flatten()
      else
        path
      end

    if url.fragment do
      [p1, @fragment_separator <> url.fragment] |> List.flatten()
    else
      p1
    end
  end

  def split(path) do
    path
  end

  @doc """
  Prepends given `prefix` to `input`. Returns the same type as
  the input type.
  """

  def add_prefix(input, nil), do: input
  def add_prefix(input, prefix) when is_list(input), do: [prefix | input]
  def add_prefix(input, prefix), do: join([prefix, input])

  @doc ~S"""
  Creates a match pattern for binary path, segments list and AST. The result
  is input type agnostic.

  Provides an option to bind parameters. This is disabled by default as it
  may cause "unused variables" warnings and the result is less compatible.
  Notice how the last example binds to `product` as `id` is not known.

  **Options**
    - `bind`: bind any parameter to a named variable. (default: `false`)

  **Example**
      iex> path_binary = "/products/:id/show/edit?_action=delete"
      iex> path_segments = ["products", ":id", "show", "edit?_garg=bar"]
      iex> path_ast = quote do: "/products/#{product}/show/edit?search=baz"
      iex> build_path_match(path_binary)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
      iex> build_path_match(path_segments)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
      iex> build_path_match(path_ast)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
  """

  def build_path_match({:<<>>, [], segments}) when is_list(segments) do
    build_path_match(segments)
  end

  def build_path_match(segments) when is_list(segments) do
    {segments, _binding} =
      segments |> split() |> until_query() |> until_fragments() |> rewrite_segments()

    segments
  end

  def build_path_match(path) when is_binary(path), do: build_path_match(path, :match)

  def build_path_match(%Phoenix.Router.Route{path: path, kind: kind}),
    do: build_path_match(path, kind)

  def build_path_match(path, kind) do
    url = URI.parse(path)
    path = url.path

    {_params, segments} =
      case kind do
        :forward -> Utils.build_path_match(path <> "/*_forward_path_info")
        :match -> Utils.build_path_match(path)
      end

    {segments, _binding} =
      segments
      |> split()
      |> until_query()
      |> until_fragments()
      |> rewrite_segments()

    segments
  end

  defp rewrite_segments(segments) do
    {segments, {binding, _counter}} =
      Macro.prewalk(segments, {[], 0}, fn
        {name, _meta, _}, {binding, counter}
        when is_atom(name) and name != :_forward_path_info ->
          var = Macro.var(:"arg#{counter}", __MODULE__)
          {var, {[{Atom.to_string(name), var} | binding], counter + 1}}

        @interpolate <> name, {binding, counter} ->
          var = Macro.var(:"arg#{counter}", __MODULE__)
          {var, {[{name, var} | binding], counter + 1}}

        @catch_all, {binding, counter} ->
          var = Macro.var(:"arg#{counter}", __MODULE__)
          {var, {[{@catch_all, var} | binding], counter + 1}}

        other, acc ->
          {other, acc}
      end)

    {segments, binding}
  end

  defp until_query(segments) do
    {before, _rest} = split_at_query(segments)

    before
  end

  defp after_query(segments) do
    {_before, rest} = split_at_query(segments)

    rest
  end

  defp split_at_query(segments) do
    Enum.split_while(
      segments,
      &(is_tuple(&1) or (is_binary(&1) and !String.starts_with?(&1, @query_separator)))
    )
  end

  defp until_fragments(segments) do
    {before, _rest} = split_at_fragments(segments)

    before
  end

  defp after_fragments(segments) do
    {_before, rest} = split_at_fragments(segments)

    rest
  end

  defp split_at_fragments(segments) do
    Enum.split_while(
      segments,
      &(is_tuple(&1) or (is_binary(&1) and !String.starts_with?(&1, @fragment_separator)))
    )
  end

  def recompose(orig_path, new_path, sigil_segments) do
    orig_seg = Utils.split(orig_path)
    new_seg = Utils.split(new_path)

    path_bindings =
      orig_seg
      |> Enum.with_index()
      |> Enum.filter(&String.starts_with?(elem(&1, 0), ":"))
      |> Map.new()

    split_sigil_segments = split(sigil_segments)
    query_part = after_query(split_sigil_segments)
    fragments_part = after_fragments(split_sigil_segments)

    Enum.map(new_seg, fn
      ":" <> _ = segment ->
        idx = path_bindings[segment]
        segment = Enum.at(split_sigil_segments, idx)

        # ensure the dynamic segment is seperated by a slash
        ["/", segment]

      segment ->
        segment
    end)
    |> List.flatten()
    |> Enum.concat([query_part, fragments_part])
    |> List.flatten()
    |> join_statics()
  end

  @doc """
  Joins consecutive static segments using the path separator. Splits at
  interpolation placeholders when provided with a path.
  """
  def join_statics(segments) when is_binary(segments) do
    segments |> split |> join_statics()
  end

  def join_statics([]), do: ["/"]

  def join_statics(segments) when is_list(segments) do
    sep_fn = &(Path.join(&1, &2) |> Path.absname(""))

    Enum.reduce(segments, [], &join_statics(&1, &2, sep_fn))
    |> Enum.reverse()
  end

  defp join_statics("/" <> _rest = cur, [] = acc, _sep_fn) when is_binary(cur),
    do: [cur | acc]

  defp join_statics(@query_separator <> cur, [head | tail], _sep_fn) when is_binary(head),
    do: [head <> @query_separator <> cur | tail]

  defp join_statics(@fragment_separator <> cur, [head | tail], _sep_fn) when is_binary(head),
    do: [head <> @fragment_separator <> cur | tail]

  defp join_statics(cur, [] = acc, _sep_fn) when is_binary(cur),
    do: [@path_separator <> cur | acc]

  defp join_statics(cur, [] = acc, _sep_fn), do: [cur | acc]

  defp join_statics(@interpolate <> _rest = cur, [prev | rest], _sep_fn)
       when is_binary(prev) and is_binary(cur),
       do: [cur, prev | rest]

  defp join_statics(cur, [@interpolate <> _rest = prev | rest], _sep_fn)
       when is_binary(prev) and is_binary(cur),
       do: [@path_separator <> cur, prev | rest]

  defp join_statics(cur, [prev | rest], sep_fn) when is_binary(prev) and is_binary(cur),
    do: [sep_fn.(prev, cur) | rest]

  defp join_statics(cur, [prev | rest] = acc, sep_fn)
       when is_binary(prev) and not is_binary(cur) do
    # TODO: Sleep some, then fix it.

    if String.ends_with?(prev, @query_separator) or String.ends_with?(prev, @fragment_separator) do
      [cur | acc]
    else
      stupid_join = sep_fn.(prev, "a") |> String.trim_trailing("a")
      [cur, stupid_join | rest]
    end
  end

  defp join_statics(cur, [prev | rest], sep_fn) when not is_binary(prev) and is_binary(cur) do
    [sep_fn.("", cur), prev | rest]
  end

  defp join_statics(cur, acc, _sep_fn), do: [cur | acc]
end
