defmodule Routex.Extension.SimpleLocale do
  @moduledoc """
  Provides Liveview lifecycle hooks and Plug to set the language, region and
  locale attributes during runtime.

  Locales can be derived from the accept-language header, a query parameter, a
  url parameter, a body parameter, the route or the session for the current
  process.

  Supports languages and regions defined in the [IANA Language Subtag
  Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)

   > #### Experimental {: .warning}
   > This module is experimental and may be subject to change

  Examples of supported packages:
  - Gettext
  - Fluent
  - Cldr

  ## Options

  ### Fields
  Multiple fields can be configured with suffixes `_sources` and `_params`.
  By default, `region` and `language` are derived from `locale`.

   * `:locale`
   * `:region`
   * `:language`

  ### Sources
  List of sources to examine for this field.
  The valid options are:

  * `:accept_language` will parse the `accept-language` header
  * `:attrs` will look in the route atributes.
  * `:body` will look in `body_params`
  * `:cookie` will look in the request cookie(s)
  * `:path` will look in `path_params`
  * `:query` will look in `query_params`
  * `:session` will look in the session
  * `:subdomain` will attempt to find the info in the subdomains.

  ### Params
  List of keys in a source to examine. Defaults to the name of the field with
  fallback to `locale`.

   ## Example configuration
    ```diff
    # file lib/example_web/routex_backend.ex
    defmodule ExampleWeb.RoutexBackend do
      use Routex.Backend,
      extensions: [
        Routex.Extension.Attrs,
   +    Routex.Extension.SimpleLocale,
    ],
   +region_sources: [:accept_language, :attrs],
   +region_params: ["region"],
   +language_sources: [:query, :attrs],
   +language_params: ["language"],
   +locale_sources: [:query, :session, :accept_language, :attrs],
   +locale_params: ["locale"],
    ```

    ## `Routex.Attrs`
    **Requires**
    - none

    **Sets**
    - none

    ## Helpers
    runtime_callbacks(attrs :: T.attrs) :: :ok
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Extension.SimpleLocale
  alias SimpleLocale.Parser
  alias SimpleLocale.Registry

  @session_key :rtx

  @impl Routex.Extension
  @doc """
  Expands the attributes to include: [:language, :region, :language_display_name, :region_display_name]
  """
  def transform(routes, _backend, _env) do
    Enum.map(routes, fn route ->
      route
      |> Attrs.get()
      |> expand_attrs()
      |> then(&Attrs.put(route, &1))
    end)
  end

  @doc """
  Hook attached to the `handle_params` stage in the LiveView life cycle. Inlined by Routex.
  """
  def handle_params(params, url, socket, attrs \\ %{}) do
    uri = URI.new!(url)
    conn_map = build_conn_map(params, uri, socket)

    {:cont, update_socket_with_locales(socket, conn_map, attrs)}
  end

  @doc """
  Plug added to the Conn lifecycle. Inlined by Routex.
  """
  def plug(conn, opts, attrs \\ %{}) do
    conn
    |> update_conn_with_locales(opts, attrs)
    |> update_conn_session()
  end

  # Private functions

  defp expand_attrs(attrs) do
    language = attrs[:language] || Parser.extract_part(attrs.locale, :language)
    region = attrs[:region] || Parser.extract_part(attrs.locale, :region)

    %{
      language: language,
      region: region,
      language_display_name: get_language_name(attrs, language),
      region_display_name: get_region_name(attrs, region)
    }
    |> merge_attrs(attrs)
  end

  defp get_language_name(attrs, language) do
    attrs[:language_display_name] ||
      case Registry.language(language) do
        %{descriptions: [description | _]} -> description
        _other -> nil
      end
  end

  defp get_region_name(attrs, region) do
    attrs[:region_display_name] ||
      case Registry.region(region) do
        %{descriptions: [description | _]} -> description
        _other -> nil
      end
  end

  defp merge_attrs(new, existing) do
    Map.merge(new, existing, fn
      _k, v1, nil -> v1
      _k, nil, v2 -> v2
      _k, _v1, v2 -> v2
    end)
  end

  defp build_conn_map(params, uri, socket) do
    %{
      path_params: params,
      query_params: URI.decode_query(uri.query || ""),
      host: uri.host,
      req_headers: [],
      private: %{routex: socket.private.routex}
    }
  end

  defp update_socket_with_locales(socket, conn_map, attrs) do
    result = __MODULE__.Detect.detect_locales(conn_map, [], attrs)
    socket = Attrs.merge(socket, result)
    Phoenix.Component.assign(socket, result)
  end

  defp update_conn_with_locales(conn, opts, attrs) do
    result = __MODULE__.Detect.detect_locales(conn, opts, attrs)

    conn =
      result
      |> Enum.reduce(conn, fn {key, value}, conn ->
        Plug.Conn.assign(conn, key, value)
      end)

    Attrs.merge(conn, result)
  end

  defp update_conn_session(%{private: %{plug_session: _data}} = conn) do
    session_data = Plug.Conn.get_session(conn, @session_key) || %{}
    result = Attrs.get(conn)
    Plug.Conn.put_session(conn, @session_key, Map.merge(session_data, result))
  end

  defp update_conn_session(conn),
    do: conn |> Plug.Conn.fetch_session() |> update_conn_session()
end
