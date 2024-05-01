defmodule Routex.URI.Utils do
  @moduledoc """
  Utilities used by Routex.URI modules
  """

  @path_separator "/"

  @doc """
  Given a binary or a list of segments returns the section starting at the first
  occurence of the separator.

  ** Example
      iex> after_separator("/my/path?k=v#top", "?")
      "?k=v"
      iex> after_separator(["my", "path", "?k=v", "#top"])
      ["?k=v", "#top"]

  """
  def after_separator(binary_or_list, sep, opts \\ [])

  def after_separator(path, sep, opts) when is_binary(path) do
    str =
      path
      |> String.split(sep, parts: 2)
      |> tl()
      |> to_string()

    (Keyword.get(opts, :incl) && sep <> str) || str
  end

  def after_separator(segments, sep, opts) do
    opts = Keyword.update(opts, :incl, true, &(!&1))
    {_before, rest} = split_at_separator(segments, sep, opts)

    rest
  end

  @doc """
  Given a binary or a list of segments returns the section up to the first
  occurence of the separator.

  ** Example
      iex> until_separator("/my/path?k=v#top", "?")
      "/my/path"
      iex> until_separator(["my", "path", "?k=v", "#top"])
      ["my", "#path"]

  """
  def until_separator(binary_or_list, sep, opts \\ [])

  def until_separator(path, sep, opts) when is_binary(path) do
    str = path |> String.split(sep, parts: 2) |> hd() |> to_string()

    (Keyword.get(opts, :incl) && str <> sep) || str
  end

  def until_separator(segments, sep, opts) do
    {before, _rest} = split_at_separator(segments, sep, opts)
    before
  end

  @doc """
  Splits a binary or a list at the first occurence of a separator. The return value is a two element tuple.

  ** Options
  - `incl`: The separator is included in the first element. Default: `false`

  ** Examples
  # Todo

  """
  def split_at_separator(path_or_segments, sep, opts \\ [])

  def split_at_separator(path, sep, opts) when is_binary(path) do
    [h | t] = path |> String.split(sep, parts: 2)

    if Keyword.get(opts, :incl) do
      {to_string(h) <> sep, to_string(t)}
    else
      {to_string(h), sep <> to_string(t)}
    end
  end

  # TODO Cleanup
  @ps @path_separator
  def split_at_separator(segments, sep, opts) do
    inclusive? = Keyword.get(opts, :incl)
    # b(efore)
    # a(fter)
    # s(segment)
    {b, f} =
      Enum.reduce(segments, {[], []}, fn
        ^sep <> _ = s, {b, []} -> {b, [s | []]}
        @ps <> ^sep <> rest, {b, []} -> {[@ps | b], [sep <> rest]}
        s, {b, []} -> {[s | b], []}
        s, {b, a} -> {b, [s | a]}
      end)

    {b, f} = {Enum.reverse(b), Enum.reverse(f)}

    # move segment in inclusive mode
    {b, f} =
      cond do
        f == [] ->
          {b, f}

        inclusive? ->
          [h | t] = f
          {Enum.concat(b, [h]), t}

        true ->
          {b, f}
      end
  end
end
