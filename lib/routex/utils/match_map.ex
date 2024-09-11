defmodule Routex.MatchMap do
  alias Routex.Path

  @moduledoc """
  A MatchMap is an easy inspectable struct which can be used during compile time to match Paths' of different types.

   For efficient matching and mapping during runtime, see `Routex.URI.to_match_pattern`
  """

  @protocol_separator "://"
  @fragment_separator "#"
  @query_separator "?"
  @path_separator "/"

  # TODO: Match_MAP_ is an implementation detail what need to be abstracted

  # , dynamic: []
  defstruct length: 0, static: []

  @doc ~S"""
  Takes a path or a list of segments and creates a unique pattern which can be used to compare paths in different formats.

  **Examples**

    iex>parse("/foo/:id/show")
    %Routex.URI.MatchMap{length: 3, dynamic: %{1 => ":id"}, static: %{0 => "foo", 2 => "show"}}
    iex> parse("/foo/3/show")
    %Routex.URI.MatchMap{length: 3, dynamic: %{}, static: %{0 => "foo", 1 => "3", 2 => "show"}}
    iex> parse(["/foo/", ":id", "/show"])
    %Routex.URI.MatchMap{length: 3, dynamic: %{1 => ":id"}, static: %{0 => "foo", 2 => "show"}}
    iex> ast = quote do: "#{ast}"
    iex> parse(["/foo/", ast, "/show"])
    %Routex.URI.MatchMap{
    length: 3,
    dynamic: %{
      1 => {:<<>>, [],
       [
         {:"::", [],
          [
            {{:., [], [Kernel, :to_string]}, [from_interpolation: true],
             [{:ast, [],  Routex.PathTest}]},
            {:binary, [],  Routex.PathTest}
          ]}
       ]}
    },
    static: %{0 => "foo", 2 => "show"}
    }
  """

  def parse(input), do: new(input)

  def new(%Phoenix.Router.Route{path: path}) do
    new(path)
  end

  def new(input) when is_binary(input) do
    URI.parse(input)
    |> Map.get(:path, "")
    # being strict causes problems in pattern matching function heads
    # as runtime URI's are all static  an empty dynamic map does not match the MatchMap map.
    |> Path.split(strict: false)
    # no can't do |> Path.join_statics()
    |> new()
  end

  def new(segments) when is_list(segments) do
    grouped =
      segments
      |> Enum.with_index(fn k, v -> {v, k} end)
      |> Enum.group_by(fn
        {_idx, v} when is_tuple(v) -> :dynamic
        {_idx, ":" <> _rest} -> :dynamic
        {_idx, _v} -> :static
      end)

    # including dynamic causes pattern match isssues in function heads
    %__MODULE__{
      length: length(segments),
      static: Map.new(grouped[:static] || [])
      # dynamic: Map.new(grouped[:dynamic] || [])
    }
  end

  @doc """
  Checks if the static elements and their positions of
  the first MatchMap match those of the second MatchMap.
  Returns `true` or `false`.

  **Example

      iex> m1 = parse("/foo/:id/baz/")
      iex> m2 = parse("/foo/3/baz/")
      iex> m3 = parse("/foo/3/baz/baz")
      iex> match(m1, m2)
      true
      iex> match(m2, m1)
      false
      iex> match(m1, m3)
      false

  """
  def match?(%{length: l1} = pattern, %{length: l1} = actual) do
    Enum.all?(pattern.static, fn {k, v} -> actual.static[k] == v end)
  end

  # can we make a match for functions using the above? Two inputs where entries of 1 equa entries of 2.

  def match?(pattern, actual), do: false
end
