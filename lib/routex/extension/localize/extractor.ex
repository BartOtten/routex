defmodule Routex.Extension.Localize.Extractor do
  @moduledoc """

  Extracts locale information from various sources. Handles both `Plug.Conn`
  structs and map inputs.

  Supports languages and regions defined in the [IANA Language Subtag
  Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)

  ### Sources
  List of sources to examine for this field.

  * `:accept_language` examines the `accept-language` header.
  * `:attrs` uses the (precompiled) route atributes.
  * `:body` uses `body_params`; useful when using values in API bodies.
  * `:cookie` uses the request cookie(s)
  * `:host` examines the hostname e.g `en.example.com` and `example.nl`. Returns the first match..
  * `:path` uses `path_params` such as `/:locale/products/`
  * `:query` uses `query_params` such as `/products?locale=en-US`
  * `:session` uses the session
  * `:assigns` uses the assigns stored in connection of socket

  ### Params
  List of keys in a source to examine. Defaults to the name of the field with
  fallback to `locale`.
  """

  alias Routex.Extension.Localize.Parser
  alias Routex.Extension.Localize.Registry

  @private_key :routex
  @session_key :routex

  @spec extract_from_source(Plug.Conn.t() | map(), atom(), String.t(), keyword()) ::
          String.t() | nil
  def extract_from_source(conn_like, source, param, attrs)

  # Handle Plug.Conn specific extractions
  def extract_from_source(%Plug.Conn{} = conn, :accept_language, param, _attrs) do
    conn
    |> Plug.Conn.get_req_header("accept-language")
    |> Parser.parse_accept_language()
    |> Enum.sort_by(& &1.quality, :desc)
    |> find_first_valid_locale(param)
  end

  def extract_from_source(%Plug.Conn{cookies: %{}} = conn, :cookie, param, _attrs) do
    conn
    |> Map.get(:cookies)
    |> Map.get(param)
  end

  def extract_from_source(%Plug.Conn{} = conn, :cookie, param, attrs) do
    conn |> Plug.Conn.fetch_cookies() |> extract_from_source(:cookie, param, attrs)
  end

  def extract_from_source(%Plug.Conn{} = conn, :query, param, _attrs) do
    conn
    |> ensure_query_params_fetched()
    |> Map.get(:query_params)
    |> Map.get(param)
  end

  def extract_from_source(%Plug.Conn{private: %{plug_session: _}} = conn, :session, param, _attrs) do
    case Plug.Conn.get_session(conn, @session_key) do
      nil -> nil
      data when is_map(data) -> Map.get(data, param)
      _other -> nil
    end
  end

  def extract_from_source(%Plug.Conn{} = conn, :session, param, attrs),
    do: conn |> Plug.Conn.fetch_session() |> extract_from_source(:session, param, attrs)

  def extract_from_source(%Plug.Conn{} = conn, :path, param, _attrs) do
    Map.get(conn.path_params || %{}, param)
  end

  # Handle Map/Struct inputs
  def extract_from_source(%{} = source, :accept_language, param, _attrs) do
    case Map.get(source, :private) do
      %{@private_key => %{session: session}} -> Map.get(session || %{}, param)
      _none -> nil
    end
  end

  def extract_from_source(%{} = source, :assigns, param, _attrs) do
    case Map.get(source, :assigns) do
      nil -> nil
      assigns -> Map.get(assigns, String.to_existing_atom(param))
    end
  end

  def extract_from_source(%{} = source, :cookie, param, _attrs) do
    case Map.get(source, :cookies) do
      nil -> nil
      cookies -> Map.get(cookies, param)
    end
  end

  def extract_from_source(%{} = source, :query, param, _attrs) do
    source
    |> Map.get(:query_params, %{})
    |> Map.get(param)
  end

  def extract_from_source(%{} = source, :session, param, _attrs) do
    with %{private: %{@private_key => %{session: session}}} <- source,
         true <- is_map(session) do
      Map.get(session, param)
    else
      _none -> nil
    end
  end

  def extract_from_source(%{} = source, :path, param, _attrs) do
    source
    |> Map.get(:path_params, %{})
    |> Map.get(param)
  end

  # Handle host extraction for both types
  def extract_from_source(source, :host, _param, _attrs) when is_map(source) do
    with host when is_binary(host) <- Map.get(source, :host),
         segments <- String.split(host, ".") do
      find_first_valid_segment(segments)
    else
      _none -> nil
    end
  end

  # Handle body params for both types
  def extract_from_source(source, :body, param, _attrs) when is_map(source) do
    source
    |> Map.get(:body_params, %{})
    |> Map.get(param)
  end

  # Handle attrs extraction for both types
  def extract_from_source(_source, :attrs, param, attrs) do
    Map.get(attrs || %{}, String.to_existing_atom(param))
  end

  # Fallback for unhandled cases
  def extract_from_source(_source, _type, _param, _attrs), do: nil

  # Private helper functions
  defp ensure_query_params_fetched(%Plug.Conn{query_params: %Plug.Conn.Unfetched{}} = conn) do
    Plug.Conn.fetch_query_params(conn)
  end

  defp ensure_query_params_fetched(conn), do: conn

  defp find_first_valid_locale(entries, param) do
    param_atom = String.to_existing_atom(param)

    Enum.find_value(entries, fn entry ->
      value = Map.get(entry, param_atom)
      validate_locale_value(value)
    end)
  end

  defp find_first_valid_segment([]), do: nil
  defp find_first_valid_segment([last]), do: (Registry.cctld?(last) && last) || nil

  defp find_first_valid_segment([h | t]) do
    if validate_locale_value(h) do
      h
    else
      find_first_valid_segment(t)
    end
  end

  defp validate_locale_value(nil), do: nil

  defp validate_locale_value(value) when is_binary(value) do
    cond do
      Registry.region?(value) -> value
      Registry.language?(value) -> value
      true -> nil
    end
  end

  defp validate_locale_value(_other), do: nil
end
