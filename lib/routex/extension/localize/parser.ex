defmodule Routex.Extension.Localize.Parser do
  @moduledoc """
  Handles parsing of locale strings.
  Uses efficient binary pattern matching and follows RFC 5646 BCP 47 language tag format.
  """

  alias Routex.Extension.Localize.Types, as: T

  @separator_chars [?-, ?_]

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
  @spec parse_locale(String.t()) :: T.locale_entry() | nil
  def parse_locale(locale)

  def parse_locale(locale) when is_binary(locale) and byte_size(locale) > 0 do
    with {language, region} <- extract_locale_parts(locale),
         true <- valid_language?(language) do
      build_locale_entry(language, region, locale)
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

  # Private functions for locale entry creation

  @spec build_locale_entry(String.t(), String.t() | nil, String.t()) :: T.locale_entry()
  defp build_locale_entry(language, region, original_locale) do
    %{
      language: language,
      region: region,
      territory: region,
      locale: original_locale
    }
  end

  @spec valid_language?(String.t() | nil) :: boolean()
  defp valid_language?(<<_lang::binary-size(2)>>), do: true
  defp valid_language?(<<_lang::binary-size(3)>>), do: true
  defp valid_language?(_other), do: false
end
