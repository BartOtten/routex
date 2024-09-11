defmodule Routex.Path do
  @moduledoc """
  Functions working withg the URI components "Path", "Query" and "Fragment".
  """

  alias Routex.URI.Utils

  @interpolate ":"
  @catch_all "*"
  @query_separator "?"
  @fragment_separator "#"
  @path_separator "/"
  @root @path_separator

  defstruct [:path, :query, :fragment]

  @doc ~S"""
  Creates a match pattern for binary path, segments list and AST. The result
  is input type agnostic.

  **Example**
      iex> path_binary = "/products/:id/show/edit?_action=delete"
      iex> path_segments = ["products", ":id", "show", "edit?search=bar"]
      iex> path_ast = quote do: "/products/#{product}/show/edit?search=baz"
      iex> to_match_pattern(path_binary)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
      iex> to_match_pattern(path_segments)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
      iex> to_match_pattern(path_ast)
      ["products", {:arg0, [], Routex.Path}, "show", "edit"]
  """

  def to_match_pattern(input)

  def to_match_pattern(path) when is_binary(path) do
    path
    |> split()
    # |> join_statics()
    |> to_match_pattern()
  end

  def to_match_pattern({:<<>>, [], segments}) do
    to_match_pattern(segments)
  end

  def to_match_pattern(segments) when is_list(segments) do
    {segments, _binding} =
      segments
      # |> Routex.URI.parse()
      # |> Map.get(:path_segments)
      # |> join_statics()
      |> rewrite_segments()

    segments
  end

  def with_tail([]), do: quote(do: [tl])

  def with_tail(segments) do
    # accept trailers
    quote do
      [unquote_splicing(segments) | tl]
    end
  end

  # Using universal binding names as the binding names
  # might not be available
  defp rewrite_segments(segments) do
    {segments, {binding, _counter}} =
      Macro.prewalk(segments, {[], 0}, fn
        {name, _meta, _args}, {binding, counter}
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

  def recompose(path, from, to) when is_binary(path),
    do: recompose(split(path, strict: true), from, to)

  def recompose(segments, from, to) do
    from_segments_template = split(from, strict: true)
    to_segments_template = split(to, strict: true)
    path = Routex.URI.parse(segments)
    path_segments = split(segments, strict: true)

    new_path =
      Enum.map(to_segments_template, fn
        ":" <> _ = segment ->
          idx = Enum.find_index(from_segments_template, &(&1 == segment))

          interpol_segment = Enum.at(path_segments, idx)
          # Binding values might be suffixed by a slash. This should be removed
          # during recomposition as in templates the suffix slash of a binding
          # is included as a separate element.
          case interpol_segment do
            <<_::binary>> ->
              String.replace_suffix(interpol_segment, "/", "")

            _ ->
              interpol_segment
          end

        segment ->
          segment
      end)

    [new_path, path.query, path.fragment] |> Enum.reject(&is_nil/1) |> List.flatten()
  end

  @doc """
  Joins consecutive static segments using the path separator. Splits at
  interpolation placeholders when provided with a path.
  """
  def join_statics(segments, opts \\ [strict: true])

  def join_statics(segments, opts) when is_binary(segments) do
    segments |> split(opts) |> join_statics(opts)
  end

  def join_statics([], _), do: ["/"]

  def join_statics(segments, opts),
    do: segments |> List.flatten() |> do_join_statics([], opts) |> Enum.reverse()

  defp do_join_statics(segments, acc, opts) do
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
      l1 == [] -> do_join_statics(tl(l2), [hd(l2) | acc], opts)
      true -> do_join_statics(l2, [join(l1, opts) | acc], opts)
    end
  end

  defp dedup_separator(str) do
    new = String.replace(str, @path_separator <> @path_separator, @path_separator)
    if new == str, do: new, else: dedup_separator(new)
  end

  @doc """
  An incomplete yet effective way to guard on AST
  """
  defguard is_ast(input) when is_tuple(input) and tuple_size(input) == 3

  def get_interpol_binding(x),
    do: x |> Macro.to_string() |> String.replace("\"", "")

  def set_interpol_binding(binding) do
    # quote do
    #   <<Kernel.to_string(unquote(Macro.var(binding, Routex.PathTest)))::binary>>
    # end

    {
      :<<>>,
      [],
      [
        {
          :"::",
          [],
          [
            {
              {:., [], [Kernel, :to_string]},
              [{:from_interpolation, true}],
              [{binding, [], Routex.PathTest}]
            },
            {:binary, [], Routex.PathTest}
          ]
        }
      ]
    }
  end

  # pushes trailing slash from interpolation to a new segment
  def convert_segment(@interpolate <> _ = interpol, acc, true = _strict?) do
    trailing = (String.ends_with?(interpol, "/") && "/") || ""

    case acc do
      [] ->
        [String.replace_suffix(interpol, "/", ""), trailing]

      [h | t] ->
        [String.replace_suffix(interpol, "/", ""), trailing, h | t]
    end
  end

  def convert_segment("_{" <> rest, acc, strict?) do
    trailing = (strict? && String.ends_with?(rest, "}/") && "/") || ""

    binding =
      rest
      |> String.replace_suffix("/", "")
      |> String.replace_suffix("}", "")
      |> String.to_atom()
      |> set_interpol_binding()

    case acc do
      [h | t] -> [binding, (strict? && @path_separator) || "", h | t]
      [] -> [binding, trailing]
    end
  end

  def convert_segment(x, acc, _strict?), do: [x | acc]

  @doc """
  Converts the `input` to a list of segments. It's a convenience wrapper for
  Plug.Router.Utils.split/1 to also handle nil value and segment lists. Additionally, non path segments will always be concatenated in a separate segment.

   ** Opts

  - `strict` - Preserve path separators (default: `false`)

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
    strict? = Keyword.get(opts, :strict, false)

    # replace interpolation #{} as it deceives parse fragment
    input = String.replace(input, ~S"#{", "_{")
    url = URI.parse(input)

    path =
      (url.path || "")
      |> String.split(~r{([^/]*[/])}, include_captures: true)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reverse()
      |> Enum.map(fn
        x when strict? -> x
        x -> String.replace_suffix(x, "/", "")
      end)
      |> Enum.reduce([], &convert_segment(&1, &2, strict?))
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

  @doc ~S"""
  Joins a (nested) list of path segments into a binary path.

  - convers atoms and integers to binary
  - converts interpolation AST to a binary representation
  - returns a path when an empty list is provided
  - skips `nil` elements

  ** Opts

  - `strict` - Join segments without path separator injection nor deduplication (default: `false`).

  ** Examples
    iex> join(["test/", "/", "path"])
    "test/path"
    iex> join(["test/", "/", "path"], strict: true)
    "test//path"
    iex> join(["/", "/test", "path/"])
    "/test/path/"
    iex> ast = quote do: "#{interpol}"
    iex> join(["test", ast, "bar"])
    ~S"test/#{interpol}/bar"

  """

  def join(segments, opts \\ []) do
    strict? = Keyword.get(opts, :strict, false)

    uri = Routex.URI.parse(segments)

    path_segments = segs_to_binaries(uri.path_segments)
    query_segments = segs_to_binaries(uri.query)
    fragment_segments = segs_to_binaries(uri.fragment)

    path_binary =
      if strict? do
        Enum.join(path_segments, "")
      else
        path_segments |> Enum.join(@path_separator) |> dedup_separator()
      end

    to_string([path_binary, query_segments, fragment_segments])
  end

  defp segs_to_binaries(segments) when is_list(segments),
    do:
      segments
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&seg_to_binary/1)

  defp segs_to_binaries(segment) when is_binary(segment), do: segment
  defp segs_to_binaries(nil), do: ""

  defp seg_to_binary(segment) when is_integer(segment), do: to_string(segment)
  defp seg_to_binary(segment) when is_atom(segment), do: ":" <> to_string(segment)
  defp seg_to_binary(segment) when is_ast(segment), do: get_interpol_binding(segment)
  defp seg_to_binary(segment) when is_binary(segment), do: segment
  def path(input) when is_binary(input), do: URI.parse(input).path

  def path(segments) when is_list(segments),
    do:
      segments
      |> Utils.after_separator(@protocol_separator)
      |> Utils.after_separator(@path_separator)
      |> Utils.until_separator(@query_separator)
      |> Utils.until_separator(@fragment_separator)

  def query(input) when is_binary(input), do: URI.parse(input).query

  def query(segments) when is_list(segments),
    do:
      segments
      |> Utils.after_separator(@query_separator)
      |> Utils.until_separator(@fragment_separator)

  def fragment(input) when is_binary(input), do: URI.parse(input).fragment

  def path(segments) when is_list(segments),
    do:
      segments
      |> Utils.after_separator(@fragment_separator)

  def to_binary(%__MODULE__{} = map) do
    to_string(map.path) <> to_string(map.query) <> to_string(map.fragment)
  end

  def to_list(%__MODULE__{} = map) do
    Enum.concat([map.path, map.query, map.fragment])
  end

  @doc """
  Returns an absolute version of the provided input, ensuring that any trailing slash, or lack thereof, is maintained.

  **Examples**
     iex> absname("/")
     "/"
     iex> absname("foo/bar/")
     "/foo/bar/"
     iex> absname(["/"])
     ["/"]
     iex> absname(["foo/", "bar/"])
     ["/", "foo/", "bar/"]
  """

  def absname(@root <> _rest = path), do: path
  def absname(path) when is_binary(path), do: @root <> path
  def absname([@root <> _rest | _t] = segments), do: segments
  def absname(segments) when is_list(segments), do: [@root | segments]

  @doc """
  Returns an relative version of the provided input, ensuring that any trailing slash, or lack thereof, is maintained.

  **Examples**
      iex> relative("/")
      ""
      iex> relative("/foo/bar")
      "foo/bar"
      iex> relative("D:/foo/bar/")
      "foo/bar/"
      iex> relative(["/"])
      []
      iex> relative(["/", "foo", "bar"])
      ["foo", "bar"]
  """

  def relative(<<_drive, ?:, ?/, rest::binary>>), do: rest
  def relative(@root <> rest), do: rest
  def relative([@root | t]), do: t
  def relative([@root <> rest | t]), do: [rest | t]

  @doc """
  Prepends given `prefix` to `input`. Returns the same type as
  the input type.
  """

  def add_prefix(input, nil), do: input
  def add_prefix([_ | _] = input, prefix), do: [prefix | input]
  def add_prefix(<<_::binary>> = input, <<_::binary>> = prefix), do: prefix <> input

  @doc """
  Removes given `prefix` from `input`. Returns the same type as
  the input type.
  """

  def remove_prefix(input, nil), do: input
  def remove_prefix([prefix | rest], prefix), do: rest

  def remove_prefix(<<_::binary>> = input, <<_::binary>> = prefix),
    do: String.replace_prefix(input, prefix, "")

  def remove_prefix(input, _prefix), do: input
end
