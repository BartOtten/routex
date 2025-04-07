defmodule Routex.Extension.SimpleLocale do
  @moduledoc """
   This extension enhances locale handling both at compile time and at runtime.
   At compile time it generates localized routes based on locales provided by a
   user or derived from Gettext. At runtime it detects a locale sourced
   from multiple locations .

   It also includes a simple [IANA Language Subtag Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry) 
   based locale registry for common locale needs such as locale tag verification and conversion to display names.

   > **Together with....**
   > This extension generates configuration for alternative route branches.
   > To convert those to routes, `Routex.Extension.Alternatives` is automatically
   > enabled.

   > **Integration:**
   > This extension sets runtime attributes (`Routex.Attrs`).
   > To use these attributes in libraries such as Gettext and Cldr, see
   > `Routex.Extension.RuntimeCallbacks`.


  ## Compile Time

  The options `locales` and `default_locale` are used to automatically generate
  localized route branches with the `locale` attribute set. This `locale` attribute
  is conveniently expanded into:
  - `locale`
  - `language`
  - `region`
  - `language_display_name`
  - `region_display_name`.

  ## Runtime
  This extension provides:

    - A LiveView lifecycle hook (`handle_params/4`) to update the socket with locale-related attributes.
    - A Plug (`plug/3`) to update the connection with locale attributes and store them in the session.

  Both are optimize for performance and are automatically enabled by
  using `Routex.Extension.Plugs` and `Routex.Extension.LiveViewHooks`.

  Locale values can be sourced from multiple locations independently, such as:
    - The `Accept-Language` header
    - Query parameters
    - URL or body parameters
    - Route attributes
    - Session data

  ## Included locale registry
  The included locale registry is ideal when your project does not need a full scale localization
  registry (yet). It provides just enough for the most common developer needs.

  The functions `language/1` and `region/1` translate locale, region, and language identifiers
  into human-readable display names. Validation functions (`language?` and
  `region?`) ensure input is valid.

  Refer to `Routex.Extension.SimpleLocale.Registry` for details.

  ```
  iex> Routex.Extension.SimpleLocale.Registry.language("nl-BE")
  %{descriptions: ["Dutch", "Flemish"], type: :language}

  iex> Routex.Extension.SimpleLocale.Registry.region("nl-BE")
  %{descriptions: ["Belgium"], type: :region}


  iex> Routex.Extension.SimpleLocale.Registry.language("nl")
  %{descriptions: ["Dutch", "Flemish"], type: :language}

  iex> Routex.Extension.SimpleLocale.Registry.region("BE")
  %{descriptions: ["Belgium"], type: :region}
  ```

  ## Options
  The extension follow the "Simple by default, powerful when needed" mantra by
  using sane defaults but offer many configuration options. It allows you to tweak
  it's behaviour to align with your project and requirements.

  The options are split options for **route generation at compile time** and
  options for **locale detection at runtime**.

   ---

  ### Route generation options
  - `locales`: A list of locale definitions. Each entry can be either:

    - A simple locale string (e.g. `"en"`, `"fr"`, `"de"`)
    - A tuple of the form `{locale, attrs}` to override or add attributes for that locale

    **Example:**

    ```elixir
    locales: [
      {"en-001", %{region_display_name: "Global"}},
      "en",
      "fr"
    ]
    ```

  - `default_locale`: The default locale for top-level navigation. Defaults to Gettext’s default locale
    (or fallbacks to `"en"` if Gettext default locale not set).

  > #### Tip: Integration with Gettext
  > You can synchronize locale routes with Gettext as follows:
  >
  > ```elixir
  > locales: Gettext.known_locales(MyAppWeb.Gettext),
  > default_locale: Application.fetch_env!(:gettext, :default_locale)
  > ```

  ---

  ### Locale detection options
  The runtime locale detection mechanism is highly flexible, allowing you to
  independently source various locale attributes.

  #### Locale Attributes and Their Sources

  By default, locale-related attributes are derived from the following keys:

  - `:locale`
  - `:region`
  - `:language`

  Each attribute can be configured with its own set of sources and parameters (the
  specific parameter names to look up in the source).

  ##### Supported Sources
  - **`:accept_language`** – Extracted from the `accept-language` header.
  - **`:attrs`** – Sourced from precompiled route attributes.
  - **`:body`** – Retrieved from body parameters (ideal for API requests).
  - **`:cookie`** – Taken from request cookies.
  - **`:host`** – Derived from the hostname (e.g. `en.example.com`).
  - **`:path`** – Taken from path parameters (e.g. `/:language/products/`).
  - **`:query`** – Retrieved from query parameters (e.g. `/products?language=nl`).
  - **`:session`** – Sourced from session data.

  The default configuration uses for each locale attribute:

  ```
  #{inspect(__MODULE__.Detect.__default_sources__())}
  ```

  #### Example Backend Configuration

  Below is an example configuration for a Routex backend:

  ```elixir
  defmodule ExampleWeb.RoutexBackend do
   use Routex.Backend,
     extensions: [
       Routex.Extension.Attrs,
       Routex.Extension.SimpleLocale, # localized routes and locale detection
       Routex.Extension.RuntimeCallbacks  # Use callbacks with external libraries
     ],
     # configure locales, overriding the region_display_name of locale "nl".
     locales: ["en", "fr", {"nl", %{contact: support@company.nl, region_display_name: "Nederland"}}]
     # inherit the default locale from Gettext
     default_locale:  Application.fetch_env!(:gettext, :default_locale),
     # (Optional) Override the default sources and parameters for locale attributes:
     # region_sources: [:accept_language, :attrs],
     # region_params: ["region"],
     # language_sources: [:query, :attrs],
     # language_params: ["language"],
     # locale_sources: [:query, :session, :accept_language, :attrs],
     # locale_params: ["locale"],
     #
     # Example: Using RuntimeCallbacks to update the Gettext locale:
     runtime_callbacks: [
       {Gettext, :put_locale, [[:attrs, :language]]}
     ]
  end
  ```

  This configuration demonstrates how to integrate runtime locale detection into
  your backend, while providing the flexibility to customize the source and
  parameter names as needed.
  """

  @behaviour Routex.Extension

  alias __MODULE__.Parser
  alias __MODULE__.Registry
  alias Routex.Attrs

  @session_key :rtx
  @fallback_locale "en"
  @gettext_locale Application.compile_env(:gettext, :default_locale)

  @impl Routex.Extension
  @spec configure(keyword(), any()) :: keyword()
  def configure(config, _backend) do
    default_locale = Keyword.get(config, :default_locale) || @gettext_locale || @fallback_locale
    locales = Keyword.get(config, :locales, [])

    # Determine the default locale definition and merge its attributes.
    default_locale_def = find_locale(locales, default_locale)
    root_attrs = build_attrs(default_locale_def)

    # Create default branches if none are specified.
    alternatives_default = %{"/" => %{attrs: root_attrs}}
    branches = Keyword.get(config, :alternatives, alternatives_default)

    # Remove the default locale from branch-specific locales.
    non_default_locales = Enum.reject(locales, &match_default?(&1, default_locale))

    localized_branches = create_localized_branches(branches, non_default_locales)

    updated_alternatives = localized_branches

    config
    |> Keyword.put(:alternatives, updated_alternatives)
    |> Keyword.update(:extensions, :unused, &[Routex.Extension.Alternatives | &1])
  end

  @impl Routex.Extension
  @doc """
  Expands each route’s attributes to include:
    - `:language`
    - `:region`
    - `:language_display_name`
    - `:region_display_name`
  """
  def transform(routes, _backend, _env) do
    Enum.map(routes, &expand_route_attrs/1)
  end

  @doc """
  LiveView callback for `handle_params/4`.

  It builds a connection map from URL and parameters,
  detects locale settings, and updates the socket accordingly.
  """
  def handle_params(params, url, socket, extra_attrs \\ %{}) do
    uri = URI.new!(url)

    conn_map = %{
      path_params: params,
      query_params: URI.decode_query(uri.query || ""),
      host: uri.host,
      req_headers: [],
      private: %{routex: socket.private.routex}
    }

    updated_socket =
      socket
      |> Attrs.merge(__MODULE__.Detect.detect_locales(conn_map, [], extra_attrs))
      |> Phoenix.Component.assign(__MODULE__.Detect.detect_locales(conn_map, [], extra_attrs))

    {:cont, updated_socket}
  end

  @doc """
  Plug callback to update the connection with locale attributes.

  The plug examines various sources, assigns the locale attributes,
  and persists them in the session.
  """
  def plug(conn, opts, extra_attrs \\ %{}) do
    conn
    |> update_conn_locales(opts, extra_attrs)
    |> persist_session()
  end

  # Find the locale definition that matches the default locale.
  defp find_locale(locales, default) do
    Enum.find(locales, fn
      {locale, _attrs} -> locale == default
      locale when is_binary(locale) -> locale == default
    end) || default
  end

  # Returns true if the locale matches the default.
  defp match_default?({locale, _}, default), do: locale == default
  defp match_default?(locale, default) when is_binary(locale), do: locale == default

  # Create a map of localized branches for each provided locale.
  defp create_localized_branches(branches, locales) do
    for {base_slug, branch} <- branches, into: %{} do
      updated_branches =
        for locale <- locales do
          locale_attrs = build_attrs(locale)
          merged_attrs = merge_attrs(branch[:attrs], locale_attrs)

          locale_str = to_string(elem_or_self(locale))
          slug = "/" <> locale_str
          {slug, Map.put(branch, :attrs, merged_attrs)}
        end
        |> Map.new()

      {base_slug, Map.put(branch, :branches, updated_branches)}
    end
  end

  # Build attributes from a locale definition.
  defp build_attrs({locale, overrides}) do
    locale
    |> build_attrs()
    |> merge_attrs(overrides)
  end

  defp build_attrs(locale) when is_binary(locale) do
    language = Parser.extract_part(locale, :language)
    region = Parser.extract_part(locale, :region)

    %{
      language: language,
      region: region,
      language_display_name: lookup_language_name(language),
      region_display_name: lookup_region_name(region)
    }
  end

  defp elem_or_self({locale, _}), do: locale
  defp elem_or_self(locale), do: locale

  defp expand_route_attrs(route) do
    attrs = Attrs.get(route)

    language =
      attrs[:language] || Parser.extract_part(attrs.locale, :language)

    region =
      attrs[:region] || Parser.extract_part(attrs.locale, :region)

    new_attrs =
      merge_attrs(
        attrs,
        %{
          language: language,
          region: region,
          language_display_name: lookup_language_name(language, attrs),
          region_display_name: lookup_region_name(region, attrs)
        }
      )

    Attrs.put(route, new_attrs)
  end

  defp lookup_language_name(language, attrs \\ %{}) do
    attrs[:language_display_name] ||
      case Registry.language(language, :unknown) do
        %{descriptions: [desc | _]} -> desc
        _other -> nil
      end
  end

  defp lookup_region_name(region, attrs \\ %{}) do
    attrs[:region_display_name] ||
      case Registry.region(region, :unknown) do
        %{descriptions: [desc | _]} -> desc
        _other -> nil
      end
  end

  defp merge_attrs(nil, new_attrs), do: new_attrs
  defp merge_attrs(existing_attrs, nil), do: existing_attrs

  defp merge_attrs(existing_attrs, new_attrs) do
    Map.merge(existing_attrs, new_attrs, fn
      _key, existing, nil -> existing
      _key, _existing, new -> new
    end)
  end

  defp update_conn_locales(conn, opts, extra_attrs) do
    detected_attrs = __MODULE__.Detect.detect_locales(conn, opts, extra_attrs)

    updated_conn =
      Enum.reduce(detected_attrs, conn, fn {key, value}, acc ->
        Plug.Conn.assign(acc, key, value)
      end)

    Attrs.merge(updated_conn, detected_attrs)
  end

  defp persist_session(%{private: %{plug_session: _}} = conn) do
    session_data = Plug.Conn.get_session(conn, @session_key) || %{}
    updated_attrs = Attrs.get(conn)
    Plug.Conn.put_session(conn, @session_key, Map.merge(session_data, updated_attrs))
  end

  defp persist_session(conn) do
    conn |> Plug.Conn.fetch_session() |> persist_session()
  end
end
