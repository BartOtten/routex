defmodule Routex.Extension.Localize.Phoenix.Parser do
  @moduledoc """
  Handles parsing of accept-language headers.
  Uses efficient binary pattern matching and follows RFC 5646 BCP 47 language tag format.
  """

  alias Routex.Extension.Localize.Parser, as: UpstreamParser
  alias Routex.Extension.Localize.Types, as: T

  @default_quality 1.0
  @locale_separator ","
  @quality_separator ";"

  @doc """
  Parses an accept-language header into a list of locale entries.

  ## Examples

      iex> parse_accept_language("en-US,fr-FR;q=0.8")
      [
        %{language: "en", region: "US", territory: "US", locale: "en-US", quality: 1.0},
        %{language: "fr", region: "FR", territory: "FR", locale: "fr-FR", quality: 0.8}
      ]
  """
  @spec parse_accept_language(String.t() | list()) :: [T.locale_entry()]
  def parse_accept_language(header)
  def parse_accept_language([]), do: []
  def parse_accept_language([header | _rest]), do: parse_accept_language(header)

  def parse_accept_language(header) when is_binary(header) do
    header
    |> split_accept_language()
    |> Enum.map(&parse_locale_with_quality/1)
    |> Enum.reject(&is_nil/1)
  end

  @spec split_accept_language(String.t()) :: [String.t()]
  defp split_accept_language(header) do
    header
    |> String.split(@locale_separator, trim: true)
    |> Enum.map(&String.trim/1)
  end

  @spec parse_locale_with_quality(String.t()) :: T.locale_entry() | nil
  defp parse_locale_with_quality(locale_string) do
    case locale_string_to_list(locale_string) do
      [locale, "q=" <> quality | _rest] ->
        parse_with_explicit_quality(locale, quality)

      [locale] ->
        case UpstreamParser.parse_locale(locale) do
          nil -> nil
          locale -> Map.put(locale, :quality, @default_quality)
        end
    end
  end

  defp locale_string_to_list(locale_string) do
    locale_string
    |> String.split(@quality_separator)
    |> Enum.map(&String.trim/1)
  end

  @spec parse_with_explicit_quality(String.t(), String.t()) :: T.locale_entry() | nil
  defp parse_with_explicit_quality(locale, quality) do
    with parsed_locale = %{} <- UpstreamParser.parse_locale(locale),
         parsed_quality when is_float(parsed_quality) <- parse_quality(quality) do
      Map.put(parsed_locale, :quality, parsed_quality)
    else
      _other -> nil
    end
  end

  @spec parse_quality(String.t()) :: float() | nil
  defp parse_quality(quality) when is_binary(quality) do
    case Float.parse(quality) do
      {value, ""} when value >= 0.0 and value <= 1.0 -> value
      _other -> nil
    end
  rescue
    _other -> nil
  end
end
