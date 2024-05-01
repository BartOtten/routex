defmodule Routex.URI do
  @moduledoc """
  Provides functions that work with both a binary path and a
  list of segments; unless explicitly stated otherwise.
  """
  @scheme_separator "://"
  @port_separator ":"
  @userinfo_separator "@"
  @fragment_separator "#"
  @query_separator "?"
  @path_separator "/"
  @interpolate ":"
  @catch_all "*"

  alias Routex.Path
  alias Routex.MatchMap

  defstruct scheme: nil,
            path: nil,
            path_segments: [],
            match_map: %MatchMap{},
            query: nil,
            fragment: nil,
            authority: nil,
            userinfo: nil,
            host: nil,
            port: nil

  @doc """
  Returns a binary URL when given a list with URL components. Any AST element is replaced by a
  numbered placeholder in format `:rtx_bind_{element_index}`
  """
  def to_binary(input) when is_list(input) do
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


  @doc """
  Parse a binary URI or segment list and returns a `Routex.URI` struct.
  """
  def parse(segments) when is_list(segments) do
    # rely on the heuristics of `URI.parse/1`
    uri =
      segments
      |> to_binary()

		parse(uri, segments)
	end

	def parse(url, segments \\ []) do
		uri = url
      |> URI.parse()

    path_segments =
      uri.path
      |> Path.split()
      |> Enum.flat_map(fn
        ":rtx_bind_" <> idx ->
          # save trailing and remove it
          trailing? = String.ends_with?(idx, @path_separator)
          idx = String.replace_suffix(idx, @path_separator, "")

          # fetch ast
          ast = Enum.at(segments, String.to_integer(idx))

          # return either only the ast segment, or the ast with a trailing path separator
          (trailing? && [ast, @path_separator]) || [ast]

        other ->
          [other]
      end)

    match_map = MatchMap.new(path_segments)

    uri
    |> Map.from_struct()
    |> then(&struct(__MODULE__, &1))
    |> Map.put(:match_map, match_map)
    |> Map.put(:path_segments, path_segments)
  end

	def to_matchable(uri) do
		uri = parse(uri)
		path = uri.path |> Routex.Path.to_match_pattern()
		path ++ ["?", uri.query] ++ ["#", uri.fragment]
		end
end
