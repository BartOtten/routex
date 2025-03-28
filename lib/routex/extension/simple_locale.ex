defmodule Routex.Extension.SimpleLocale do
  @moduledoc """
  Provides Liveview lifecycle hooks and Plug to set the runtime language or
  runtime locale using a call to `put_locale/{1,2}`.

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
   - `:translation_backends` - A keyword list containing package-backend
     pairs used to invoke put_locale/2 for setting the language. This function
     accepts the attribute `:language` —falling back to :locale when necessary.
     Specifying "*" for a backend applies the value to all available backends
     (the default).

   - `:locale_backends` - A keyword list containing package-backend pairs
     used to invoke put_locale/2 for setting the locale. This function accepts
     the attribute `:locale` —falling back to :language when necessary.
     Specifying "*" for a backend applies the value to all available backends
     (the default).

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
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Extension.SimpleLocale
  alias Routex.Types, as: T
  alias SimpleLocale.Parser
  alias SimpleLocale.Registry

  @session_key :rtx

  @impl Routex.Extension
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

    socket
    |> update_socket_with_locales(conn_map, attrs)
    |> then(&{:cont, &1})
  end

  @doc """
  Plug added to the Conn lifecycle. Inlined by Routex.
  """
  def plug(conn, opts, attrs \\ %{}) do
    conn
    |> Routex.Attrs.merge(attrs)
    |> detect_and_store_locales(opts, attrs)
    |> update_conn_session()
    |> put_locale_from_attrs()
  end

  @impl Routex.Extension
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  def create_helpers(_routes, backend, _env) do
    ast = build_ast(backend)

    quote do
      def put_locale(attrs) do
        (unquote_splicing(ast))
      end
    end
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
    attrs = Map.merge(attrs, result)
    attrs.__helper_mod__.put_locale(attrs)
    Phoenix.Component.assign(socket, result)
  end

  defp detect_and_store_locales(conn, opts, attrs) do
    result = __MODULE__.Detect.detect_locales(conn, opts, attrs)

    result
    |> Enum.reduce(conn, fn {key, value}, conn ->
      conn
      |> Attrs.put(key, value)
      |> Plug.Conn.assign(key, value)
    end)
  end

  defp update_conn_session(%{private: %{plug_session: _data}} = conn) do
    session_data = Plug.Conn.get_session(conn, @session_key) || %{}
    result = Attrs.get(conn)
    Plug.Conn.put_session(conn, @session_key, Map.merge(session_data, result))
  end

  defp update_conn_session(conn),
    do: conn |> Plug.Conn.fetch_session() |> update_conn_session()

  defp put_locale_from_attrs(conn) do
    attrs = Map.merge(%{}, Attrs.get(conn))
    attrs.__helper_mod__.put_locale(attrs)
    conn
  end

  defp build_ast(backend) do
    config = backend.config() |> Map.from_struct()

    for config_key <- [:translation_backends, :locale_backends],
        !is_nil(config[config_key]),
        {package, backend} <- config[config_key],
        package = Module.concat([package]),
        Code.ensure_loaded!(package) do
      build_put_locale_ast(package, backend, config_key)
    end
  end

  defp build_put_locale_ast(package, "*", :locale_backends) do
    ensure_provided!(package, 1)
    quote do: unquote(package).put_locale(attrs[:region] || attrs[:locale])
  end

  defp build_put_locale_ast(package, backend, :locale_backends) do
    ensure_provided!(package, 2)
    quote do: unquote(package).put_locale(unquote(backend), attrs[:locale])
  end

  defp build_put_locale_ast(package, "*", :translation_backends) do
    ensure_provided!(package, 1)
    quote do: unquote(package).put_locale(attrs[:language])
  end

  defp build_put_locale_ast(package, backend, :translation_backends) do
    ensure_provided!(package, 2)
    quote do: unquote(package).put_locale(unquote(backend), attrs[:language])
  end

  defp ensure_provided!(package, arity) do
    function_exported?(package, :put_locale, arity) ||
      raise "#{package} does not provide put_locale/#{arity}"
  end
end
