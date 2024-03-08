# credo:disable-for-this-file
defmodule Routex.Path do
  @moduledoc """
  Provides functions that work with both a binary path and a
  list of segments; unless explicitly stated otherwise.
  """

  @interpolate ":"
  @catch_all "*"
  @query_separator "?"
  @fragment_separator "#"
  @path_separator "/"
  @root @path_separator

  defguard is_ast(input) when is_tuple(input) and tuple_size(input) == 3

  @doc """
  Returns an absolute path, while preserving (absence of) a trailing slash.
  """
  def absname(@root <> _ = path), do: path
  def absname([@root <> _ | _] = segments), do: segments
  def absname(segments) when is_binary(segments), do: @root <> segments
  def absname(segments) when is_list(segments), do: ["/" | segments]

  @doc """
  Returns a relative path, while preserving (absence of) a trailing slash.
  """
  def relative(<<_drive, ?:, ?/, rest::binary>>), do: rest
  def relative(@root <> rest), do: rest
  def relative([@root <> rest | t]), do: [rest | t]
  def relative(path), do: path

  @doc ~S"""
  Joins a (nested) list of path segments into a binary path.

  ** Features**
  - preserves trailing slashes
  - deduplicates consecutive slashes
  - convers atoms and integers to binary
  - converts interpolation AST to a binary representation
  - returns a path when an empty list is provided
  - skips `nil` elements

  ** Examples
    iex> join(["test", "path"])
    "test/path"
    iex> join(["/", "/test", "path/"])
    "/test/path/"
    iex> ast = quote do: "#{interpol}"
    iex> join(["test", ast, "bar"])
    ~S"test/#{interpol}/bar"

  """

  def join(segments) do
    {path_segments, other} =
      segments
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn
        segment when is_integer(segment) ->
          to_string(segment)

        segment when is_atom(segment) ->
          ":" <> to_string(segment)

        segment when is_ast(segment) ->
          get_interpol_binding(segment)

        other ->
          other
      end)
      |> Enum.split_with(fn
        @fragment_separator <> "{" <> _ -> true
        @fragment_separator <> _ -> false
        @query_separator <> _ -> false
        _ -> true
      end)

    path =
      path_segments
      |> List.flatten()
      |> Enum.join(@path_separator)

    query_and_fragments =
      other
      |> Enum.join()

    (path <> query_and_fragments) |> dedup_separator()
  end

  @doc """
  Converts the `input` to a list of segments. It's a convenience wrapper for
  Plug.Router.Utils.split/1 to also handle nil value and segment lists. Additionally, non path
  segments will always be concatenated in a separate segment.

  **Examples**
      iex> split(nil)
      []
      iex> split("/foo/bar?baz=qux")
      ["foo", "bar", "?baz=qux"]
      iex> split("/foo/bar/?baz=qux")
      ["foo", "bar", "?baz=qux"]
      iex> split("/foo/bar#frag")
      ["foo", "bar", "#frag"]
      iex> split(["/foo/bar", "/baz"])
      ["foo", "bar", "baz"]
  """

  def split(_, opts \\ [])
  def split(nil, _opts), do: []

  def split(input, opts) when is_list(input) do
    for path <- input do
      split(path, opts)
    end
    |> List.flatten()
  end

  def split(input, opts) when is_binary(input) do
    preserve? = Keyword.get(opts, :preserve_separator, false)

    # replace interpolation #{} as it deceives URI.parse fragment
    input = String.replace(input, ~S"#{", "_{")
    url = URI.parse(input)

    path =
      (url.path || "")
      |> String.split(~r{([^/]*[/])}, include_captures: true)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reverse()
      |> Enum.map(fn
        x when preserve? -> x
        x -> String.replace_suffix(x, "/", "")
      end)
      |> Enum.reduce([], fn
        # pushes trailing slash from interpolation to a new segment
        @interpolate <> _ = interpol, acc when preserve? ->
          trailing = (String.ends_with?(interpol, "/") && "/") || ""

          case acc do
            [] ->
              [String.replace_suffix(interpol, "/", ""), trailing]

            [h | t] ->
              [String.replace_suffix(interpol, "/", ""), trailing, h | t]
          end

        "_{" <> rest, acc ->
          trailing = (preserve? && String.ends_with?(rest, "}/") && "/") || ""

          binding =
            rest
            |> String.replace_suffix("/", "")
            |> String.replace_suffix("}", "")
            |> String.to_atom()
            |> set_interpol_binding()

          case acc do
            [h | t] -> [binding, (preserve? && @path_separator) || "", h | t]
            [] -> [binding, trailing]
          end

        x, acc ->
          [x | acc]
      end)
      |> Enum.reject(&(&1 == ""))

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

  def split({:|, [], [static, catchall]}, _opts), do: [static, catchall]

  def split(path, _opts) do
    path
  end

  @doc """
  Prepends given `prefix` to `input`. Returns the same type as
  the input type.
  """

  def add_prefix(input, nil), do: input
  def add_prefix(input, prefix) when is_list(input), do: [prefix | input]
  def add_prefix(input, prefix), do: join([prefix, input])

  @doc """
  iex> route_pattern("/foo/3/show")
  {3, %{0 => "foo", 1 => "3", 2 => "show"}}
  iex> route_pattern("/foo/:id/show")
  {3, %{0 => "foo", 2 => "show"}}
  """

  def route_pattern(input) do
    segments =
      split(input)
      |> until_query()

    static_map =
      Enum.with_index(segments, fn k, v -> {v, k} end)
      |> Enum.reject(fn {_idx, segment} ->
        is_tuple(segment) or String.starts_with?(segment, ":")
      end)
      |> Map.new()

    {length(segments), static_map}
  end

  # TODO: outdated docs
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
      iex> to_match_pattern(path_binary)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
      iex> to_match_pattern(path_segments)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
      iex> to_match_pattern(path_ast)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
  """

  def to_match_pattern(segments, opts \\ [])

  def to_match_pattern({:<<>>, [], segments}, opts) when is_list(segments) do
    to_match_pattern(segments, opts)
  end

  def to_match_pattern(segments, opts) when is_list(segments) do
    {segments, _binding} =
      segments
      |> split(opts)
      |> until_query()
      |> until_fragments()
      |> rewrite_segments()

    segments
  end

  def to_match_pattern(path, opts) when is_binary(path), do: to_match_pattern(path, :match, opts)

  def to_match_pattern(%Phoenix.Router.Route{path: path, kind: kind}, opts),
    do: to_match_pattern(path, kind, opts)

  def to_match_pattern(path, kind, opts) do
    url = URI.parse(path)
    path = url.path || "/"

    # {_params, segments} =
    #   case kind do
    #     :forward ->
    #       Utils.build_path_match(path <> "/*_forward_path_info")

    #     :match ->
    #       Utils.build_path_match(path)
    #   end

    segments = split(path, opts) |> join_statics()

    {segments, _binding} =
      segments
      |> split(opts)
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
      &(is_tuple(&1) or
          (is_binary(&1) and
             !String.starts_with?(&1, [@query_separator, @path_separator <> @query_separator])))
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
      &(is_tuple(&1) or
          (is_binary(&1) and
             !String.starts_with?(&1, [
               @fragment_separator,
               @path_separator <> @fragment_separator
             ])))
    )
  end

  def recompose(orig_path, new_path, sigil_segments) do
    orig_seg = split(orig_path, preserve_separator: true)
    new_seg = split(new_path, preserve_separator: true)

    path_bindings =
      orig_seg
      # |> join_statics()
      # |> Enum.filter(&String.starts_with?(&1, ":"))
      |> Enum.with_index()
      |> Map.new()

    split_sigil_segments = split(sigil_segments, preserve_separator: true)
    query_part = after_query(split_sigil_segments)
    fragments_part = after_fragments(split_sigil_segments)

    # IO.inspect(split_sigil_segments, label: :SIGILSEG)

    Enum.map(new_seg, fn
      ":" <> _ = segment ->
        idx = path_bindings[segment]
        Enum.at(split_sigil_segments, idx)

      segment ->
        segment
    end)
    |> List.flatten()
    |> Enum.concat([query_part, fragments_part])
    |> List.flatten()
  end

  @doc """
  Joins consecutive static segments using the path separator. Splits at
  interpolation placeholders when provided with a path.
  """
  def join_statics(segments) when is_binary(segments) do
    segments |> split(preserve_separator: true) |> join_statics()
  end

  def join_statics([]), do: ["/"]

  def join_statics(segments), do: join_statics(segments, []) |> Enum.reverse()

  def join_statics(segments, acc) do
    {l1, l2} =
      Enum.split_while(segments, fn
        @interpolate <> _ -> false
        @catch_all <> _ -> false
        segment when is_integer(segment) -> to_string(segment)
        segment when is_binary(segment) -> true
        _ -> false
      end)

    cond do
      l1 == [] and l2 == [] -> acc
      l1 == [] -> join_statics(tl(l2), [hd(l2) | acc])
      true -> join_statics(l2, [join(l1) | acc])
    end
  end

  defp dedup_separator(str) do
    new = String.replace(str, @path_separator <> @path_separator, @path_separator)
    if new == str, do: new, else: dedup_separator(new)
  end

  def get_interpol_binding(
        {:<<>>, [],
         [
           {:"::", [],
            [
              {{:., [], [Kernel, :to_string]}, [from_interpolation: true],
               [{binding, [], Routex.PathTest}]},
              {:binary, [], Routex.PathTest}
            ]}
         ]}
      ) do
    "#" <> "{#{binding}}"
  end

  def get_interpol_binding(x),
    do: Macro.to_string(x)

  def set_interpol_binding(binding) do
    {:<<>>, [],
     [
       {:"::", [],
        [
          {{:., [], [Kernel, :to_string]}, [from_interpolation: true],
           [{binding, [], Routex.PathTest}]},
          {:binary, [], Routex.PathTest}
        ]}
     ]}
  end
end
