defmodule Routex.Extension.Localize.Phoenix.Runtime do
  @moduledoc """
  This extension provides:

  - A Plug (`plug/3`) to update the connection with locale attributes and store them
    in the session. Enabled via `Routex.Extension.Plugs`.
  - A LiveView lifecycle hook (`handle_params/4`) to update the socket with
    locale-related attributes. Enabled via `Routex.Extension.LiveViewHooks`.

  Both are optimized for performance.

  Locale values can be sourced independently from locations like:

  - Pre-compiled route attributes
  - The `Accept-Language` header sent by the client (`fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7`)
  - Query parameters (`?lang=fr`)
  - Hostname (`fr.example.com`)
  - Path parameters (`/fr/products`)
  - Assigns (`assign(socket, [locale: "fr"])`)
  - Body parameters
  - Stored cookie
  - Session data


  Runtime detection is configured by specifying sources for locale attributes
  (`:locale`, `:language`, `:region`).

  #### Locale Attributes and Their Sources

  Each attribute (`:locale`, `:language`, `:region`) can have its own list of
  sources and parameter names, where the parameter name is the key to get from
  the source. The parameter should be provided as a string.

  ##### Supported Sources
  - `:accept_language`: From the header sent by the client (e.g. `fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7`)
  - `:assigns`: From conn and socket assigns.
  - `:route`: From precompiled route attributes.
  - `:body`: From request body parameters.
  - `:cookie`: From request cookies.
  - `:host`: From the hostname (e.g., `en.example.com`).
  - `:path`: From path parameters (e.g., `/:lang/users`).
  - `:query`: From query parameters (e.g., `?locale=de`).
  - `:session`: From session data.

  ##### Default Configuration

  The default sources for each attribute are:
  `#{inspect(Routex.Extension.Localize.Phoenix.Detect.__default_sources__())}`.

  ##### Overriding Detection Behavior

  You can customize sources and parameters per attribute:

  **Examples:**
  ```elixir
  # In your Routex backend module
  locale_sources: [:query, :session, :accept_language], # Order matters
  locale_params: ["locale"], # Look for ?locale=... etc

  language_sources: [:path, :host],
  language_params: ["lang"], # Look for /:lang/... etc

  region_sources: [:route] # Only use region from precompiled route attributes
  # region_params defaults to ["region"]
  ```
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Extension.Localize.Phoenix.Detect

  alias Routex.Types, as: T
  alias Routex.Utils

  @session_key :rtx
  @locale_fields [:locale, :language, :region, :territory]
  @namespace :runtime
  @default_sources Detect.__default_sources__()
  @supported_sources Detect.__supported_sources__()
  @default_params Detect.__default_params__()

  # Typespecs
  @type conn :: Plug.Conn.t()
  @type socket :: Phoenix.LiveView.Socket.t()
  @type url :: String.t()
  @type params :: %{optional(String.t()) => any()}
  @type plug_opts :: keyword()

  @dispatch_target {Gettext, :put_locale, [[:attrs, :runtime, :language]]}

  @doc """
  Checks for invalid sources
  """
  @impl Routex.Extension
  @spec configure(T.opts(), T.backend()) :: T.opts()
  def configure(opts, backend) do
    fetch_and_validate_sources! = fn key ->
      opts |> Keyword.get(key, @default_sources) |> validate(key, backend)
    end

    fetch_params = fn key, default -> Keyword.get(opts, key, default) end

    sources =
      [
        region_sources: :region_sources |> fetch_and_validate_sources!.(),
        language_sources: :language_sources |> fetch_and_validate_sources!.(),
        locale_sources: :locale_sources |> fetch_and_validate_sources!.(),
        region_params: :region_params |> fetch_params.(@default_params.region),
        language_params: :language_params |> fetch_params.(@default_params.language),
        locale_params: :locale_params |> fetch_params.(@default_params.locale)
      ]

    new_opts =
      opts
      |> Keyword.merge(sources)
      |> Keyword.update(:dispatch_targets, [@dispatch_target], &maybe_add_dispatch_target/1)

    # this one also triggers wwhen there was no :dispatch_targets in the first place
    if new_opts != opts,
      do: Routex.Utils.print(__MODULE__, "Added dispatch target #{inspect(@dispatch_target)}")

    new_opts
  end

  defp maybe_add_dispatch_target(existing) do
    if Enum.any?(existing, fn {mod, _f, _a} -> mod == Gettext end) do
      existing
    else
      [@dispatch_target | existing]
    end
  end

  defp validate(sources, key, backend) do
    invalid_sources = sources -- @supported_sources

    if invalid_sources != [] do
      raise ArgumentError,
            """
            One or more values in #{inspect(key)} are not supported.
            Invalid: #{inspect(invalid_sources)} (#{inspect(backend)})
            """
    end

    sources
  end

  @doc """
  LiveView `handle_params/4` callback hook.

  Detects locale settings based on URL, params, and socket state, then updates
  the socket assigns and Routex attributes.
  """
  @spec handle_params(params, url, socket) :: {:cont, socket()}
  def handle_params(params, url, socket) do
    uri = URI.parse(url)
    route_attrs = socket |> Attrs.get()

    conn_map = %{
      path_params: params,
      query_params: URI.decode_query(uri.query || ""),
      host: uri.host,
      req_headers: [],
      private: socket.private || %{routex: %{}},
      assigns: socket.assigns || %{}
    }

    detected_attrs = Detect.detect_locales(conn_map, [], route_attrs)
    assign_module = Utils.assign_module()

    socket =
      socket
      |> Attrs.merge(@namespace, detected_attrs)
      |> assign_module.assign([{@namespace, Map.take(detected_attrs, @locale_fields)}])

    {:cont, socket}
  end

  @doc """
  Plug callback to detect and assign locale attributes to the connection.

  Examines configured sources (params, session, headers, etc.), updates
  `conn.assigns`, merges attributes into `conn.private.routex.attrs`, and
  persists relevant attributes in the session.
  """
  @spec call(conn, plug_opts()) :: conn()
  def call(conn, plug_opts) do
    route_attrs = Attrs.get(conn)

    conn
    |> update_conn_locales(plug_opts, route_attrs)
    |> persist_locales_to_session()
  end

  @spec update_conn_locales(conn, plug_opts(), extra_attrs :: T.attrs()) ::
          conn()
  defp update_conn_locales(conn, plug_opts, route_attrs) do
    detected_attrs = Detect.detect_locales(conn, plug_opts, route_attrs)

    conn
    |> Plug.Conn.assign(@namespace, detected_attrs)
    |> Attrs.merge(@namespace, detected_attrs)
  end

  # Persists detected locale fields (:locale, :language, :region) to the session.
  @spec persist_locales_to_session(conn :: conn()) :: conn()
  defp persist_locales_to_session(%Plug.Conn{private: %{plug_session: fetched_session}} = conn)
       when is_map(fetched_session) do
    attrs_to_persist =
      conn
      |> Attrs.get()
      |> Map.take(@locale_fields)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    if map_size(attrs_to_persist) > 0 do
      session_data = Plug.Conn.get_session(conn, @session_key) || %{}
      updated_session_data = Map.merge(session_data, attrs_to_persist)
      Plug.Conn.put_session(conn, @session_key, updated_session_data)
    else
      conn
    end
  end

  defp persist_locales_to_session(conn),
    do: conn |> Plug.Conn.fetch_session() |> persist_locales_to_session()
end
