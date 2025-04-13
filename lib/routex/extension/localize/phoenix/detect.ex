defmodule Routex.Extension.Localize.Phoenix.Detect do
  @moduledoc """
  Main module for locale detection logic.
  """

  alias Routex.Extension.Localize.Normalize
  alias Routex.Extension.Localize.Phoenix.Extractor
  alias Routex.Extension.Localize.Types
  alias Routex.Types, as: T

  @default_sources [:query, :session, :cookie, :accept_language, :path, :assigns, :attrs]

  @default_params %{
    region: ["region", "locale"],
    language: ["language", "locale"],
    territory: ["territory", "locale"],
    locale: ["locale"]
  }

  def __default_sources__, do: @default_sources
  def __default_params__, do: @default_params

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
      |> Normalize.locale_value(key)
      |> handle_detection_result(key)
    end)
  end

  defp handle_detection_result(nil, _key), do: {:cont, nil}
  defp handle_detection_result(value, _key), do: {:halt, value}

  defp add_territory_alias(result) do
    Map.put(result, :territory, result.region)
  end
end
