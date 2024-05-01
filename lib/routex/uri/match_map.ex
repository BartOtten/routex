defmodule Routex.URI.MatchMap do
  @moduledoc """
  Utilities for creating maps to be used for comparing URI components in Routex.
  """

  alias Routex.URI.Utils

  @protocol_separator "://"
  @fragment_separator "#"
  @query_separator "?"
  @path_separator "/"

  # , dynamic: []
  defstruct length: 0, static: []

  @doc ~S"""
  Takes a path or a list of segments and creates a unique pattern which can be used to compare paths in different formats.

  For efficient matching and mapping during runtime, see `Routex.URI.to_match_pattern`

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

  def parse(input) when is_binary(input) do
    URI.parse(input) |> Map.get(:path, "") |> String.split("/") |> parse()
  end

  def parse(segments) when is_list(segments) do
    grouped =
      segments
      |> Enum.with_index(fn k, v -> {v, k} end)
      |> Enum.group_by(fn
        {_idx, v} when is_tuple(v) -> :dynamic
        {_idx, ":" <> _rest} -> :dynamic
        {_idx, _v} -> :static
      end)

    %__MODULE__{
      length: length(segments),
      static: Map.new(grouped[:static] || [])
      # dynamic: Map.new(grouped[:dynamic] || [])
    }
  end
end
