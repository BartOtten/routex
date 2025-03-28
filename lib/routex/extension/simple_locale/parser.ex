defmodule Routex.Extension.SimpleLocale.Parser do
  @moduledoc """
  Handles parsing of locale strings and accept-language headers.
  Uses efficient binary pattern matching and follows RFC 5646 BCP 47 language tag format.
  """

  alias Routex.Extension.SimpleLocale.Types

  @default_quality 1.0
  @separator_chars [?-, ?_]

  @doc """
  Parses an accept-language header into a list of locale entries.

  ## Examples

      iex> parse_accept_language("en-US,fr-FR;q=0.8")
      [
        %{language: "en", region: "US", territory: "US", locale: "en-US", quality: 1.0},
        %{language: "fr", region: "FR", territory: "FR", locale: "fr-FR", quality: 0.8}
      ]
  """
  @spec parse_accept_language(String.t() | list()) :: [Types.locale_entry()]
  def parse_accept_language(header)
  def parse_accept_language([]), do: []
  def parse_accept_language([header | _rest]), do: parse_accept_language(header)

  def parse_accept_language(header) when is_binary(header) do
    header
    |> split_accept_language()
    |> Enum.map(&parse_locale_with_quality/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Parses a single locale string into a locale entry.

  ## Examples

      iex> parse_locale("en-US")
      %{language: "en", region: "US", territory: "US", locale: "en-US", quality: 1.0}

      iex> parse_locale("fra")
      %{language: "fra", region: nil, territory: nil, locale: "fra", quality: 1.0}

      iex> parse_locale("")
      nil
  """
  @spec parse_locale(String.t()) :: Types.locale_entry() | nil
  def parse_locale(locale)

  def parse_locale(locale) when is_binary(locale) and byte_size(locale) > 0 do
    with {language, region} <- extract_locale_parts(locale),
         true <- valid_language?(language) do
      build_locale_entry(language, region, locale, @default_quality)
    else
      _other -> nil
    end
  end

  def parse_locale(_other), do: nil

  @spec extract_locale_parts(String.t()) :: {String.t() | nil, String.t() | nil}
  def extract_locale_parts(value) when is_binary(value) do
    language = extract_part(value, :language)
    region = extract_part(value, :region)
    {language, region}
  end

  @spec extract_part(String.t(), :language | :region) :: String.t() | nil
  def extract_part(value, :language) do
    case value do
      <<lang::binary-size(2)>> -> lang
      <<lang::binary-size(3)>> -> lang
      <<lang::binary-size(2), sep, _rest::binary>> when sep in @separator_chars -> lang
      <<lang::binary-size(3), sep, _rest::binary>> when sep in @separator_chars -> lang
      _other -> nil
    end
  end

  def extract_part(value, :region) do
    case value do
      <<_part::binary-size(2), sep, rest::binary>> when sep in @separator_chars and rest != "" ->
        rest

      <<_part::binary-size(3), sep, rest::binary>> when sep in @separator_chars and rest != "" ->
        rest

      _other ->
        nil
    end
  end

  @spec split_accept_language(String.t()) :: [String.t()]
  defp split_accept_language(header) do
    header
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  @spec parse_locale_with_quality(String.t()) :: Types.locale_entry() | nil
  defp parse_locale_with_quality(locale_string) do
    case locale_string_to_list(locale_string) do
      [locale, "q=" <> quality | _rest] -> parse_with_explicit_quality(locale, quality)
      [locale] -> parse_locale(locale)
    end
  end

  defp locale_string_to_list(locale_string) do
    locale_string
    |> String.split(";")
    |> Enum.map(&String.trim/1)
  end

  @spec parse_with_explicit_quality(String.t(), String.t()) :: Types.locale_entry() | nil
  defp parse_with_explicit_quality(locale, quality) do
    with parsed_locale = %{} <- parse_locale(locale),
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

  # Private functions for locale entry creation

  @spec build_locale_entry(String.t(), String.t() | nil, String.t(), float()) ::
          Types.locale_entry()
  defp build_locale_entry(language, region, original_locale, quality) do
    %{
      language: language,
      region: region,
      territory: region,
      locale: original_locale,
      quality: quality
    }
  end

  @spec valid_language?(String.t() | nil) :: boolean()
  defp valid_language?(<<_lang::binary-size(2)>>), do: true
  defp valid_language?(<<_lang::binary-size(3)>>), do: true
  defp valid_language?(_other), do: false
end
