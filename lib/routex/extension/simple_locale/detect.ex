defmodule Routex.Extension.SimpleLocale.Detect do
  @moduledoc """
  Main module for locale detection logic.
  """

  alias Routex.Extension.SimpleLocale
  alias Routex.Types, as: T
  alias SimpleLocale.Extractor
  alias SimpleLocale.Types

  @default_sources [:session, :query, :path, :accept_language, :attrs]

  @default_params %{
    region: ["region", "locale"],
    language: ["language", "locale"],
    territory: ["territory", "locale"],
    locale: ["locale"]
  }

  @spec detect_locales(Plug.Conn.t() | map(), keyword(), T.attrs()) :: Types.locale_result()
  def detect_locales(conn_or_map, _options, attrs) do
    backend = attrs[:__backend__]
    opts = backend.config()

    sources_config = build_sources_config(opts)
    params_config = build_params_config(opts)

    sources_config
    |> detect_locale_values(conn_or_map, params_config, attrs)
    |> add_territory_alias()
  end

  defp build_sources_config(opts) do
    %{
      region: Map.get(opts, :region_sources, @default_sources),
      language: Map.get(opts, :language_sources, @default_sources),
      locale: Map.get(opts, :locale_sources, @default_sources)
    }
  end

  defp build_params_config(opts) do
    %{
      region: Map.get(opts, :region_params, @default_params.region),
      language: Map.get(opts, :language_params, @default_params.language),
      locale: Map.get(opts, :locale_params, @default_params.locale)
    }
  end

  defp detect_locale_values(sources_config, conn_or_map, params_config, attrs) do
    Enum.reduce(sources_config, %{}, fn {key, sources}, acc ->
      value =
        Enum.find_value(params_config[key], fn param ->
          detect_value_from_sources(sources, conn_or_map, key, param, attrs)
        end)

      Map.put(acc, key, value)
    end)
  end

  defp detect_value_from_sources(sources, conn_or_map, key, param, attrs) do
    Enum.reduce_while(sources, nil, fn source, _acc ->
      conn_or_map
      |> Extractor.extract_from_source(source, param, attrs)
      |> normalize_locale_value(key)
      |> handle_detection_result(key)
    end)
  end

  def normalize_locale_value(nil, _key), do: nil
  def normalize_locale_value(value, :locale), do: value

  # credo:disable-for-next-line
  def normalize_locale_value(value, key) when key in [:region, :language] do
    case value do
      <<input::binary-size(2)>> ->
        if(key == :language, do: String.downcase(input), else: String.upcase(input))

      <<input::binary-size(3)>> ->
        if(key == :language, do: String.downcase(input), else: String.upcase(input))

      <<lang::binary-size(2), ?-, rest::binary>> ->
        if(key == :language, do: String.downcase(lang), else: String.upcase(rest))

      <<lang::binary-size(3), ?-, rest::binary>> ->
        if(key == :language, do: String.downcase(lang), else: String.upcase(rest))

      <<lang::binary-size(2), ?_, rest::binary>> ->
        if(key == :language, do: String.downcase(lang), else: String.upcase(rest))

      <<lang::binary-size(3), ?_, rest::binary>> ->
        if(key == :language, do: String.downcase(lang), else: String.upcase(rest))

      _other ->
        nil
    end
  end

  defp handle_detection_result(nil, _key), do: {:cont, nil}
  defp handle_detection_result(value, _key), do: {:halt, value}

  defp add_territory_alias(result) do
    Map.put(result, :territory, result.region)
  end
end
