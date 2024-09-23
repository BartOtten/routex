defmodule Routex.Path do
  @moduledoc """
  Functions working withg the URI components "Path", "Query" and "Fragment".
  """

  @interpolate ":"
  # @catch_all "*"
  @query_separator "?"
  @fragment_separator "#"
  @path_separator "/"
  @root @path_separator

  defstruct [:path, :query, :fragment]

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

  @doc """
  Returns a binary URL when given a list with URL components. Any AST element is replaced by a
  numbered placeholder in format `:rtx_bind_{element_index}`
  """
  def list_to_binary(input) when is_list(input) do
    input
    |> Enum.with_index()
    |> Enum.map(fn
      {{_, _, _}, pos} ->
        ":rtx_bind_#{pos}"

      {other, _pos} ->
        other
    end)
    |> Enum.join("/")
    |> to_string()
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

    uri = segments |> list_to_binary() |> URI.parse()

    path_segments = (uri.path || "") |> Path.split()
    query_segments = uri.query || ""
    fragment_segments = uri.fragment || ""

    path_binary =
      if strict? do
        Enum.join(path_segments, "")
      else
        path_segments |> Enum.join(@path_separator) |> dedup_separator()
      end

    to_string([path_binary, query_segments, fragment_segments])
  end

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
