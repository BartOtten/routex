defmodule Routex.Extension.SimpleLocale do
  @moduledoc """
  This extension adds locale handling both at compile time and at runtime.

  > #### Simple by default, powerful when needed.
  > For easy setup this extension works by default without additional configuration.
  > Yet, it has many powerful options to support the most exotic use cases. Feel free
  > to skip to the [simple configuration example](#module-configuration-examples)
  > and come back when you need custom behaviour.


  At compile time, this extension generates localized routes based on provided locales (or
  derived from Gettext). At runtime, it detects the locale from various sources.

  Includes a simple locale registry based on the
  [IANA Language Subtag Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
  for common tasks like locale tag verification and display name conversion.


  ## Route Generation (Compile Time)

  The `:locales`, `:default_locale` and `locale_branch_sources` options generate localized routes
  with the `:locale` attribute set. This attribute is expanded into:

  - `:locale` (e.g., "en-US")
  - `:language` (e.g., "en")
  - `:region` (e.g., "US")
  - `:language_display_name` (e.g., "English")
  - `:region_display_name` (e.g., "United States")


  ## Locale Detection (Runtime)

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


  ## Build-in Locale Registry

  The built-in locale registry (`Routex.Extension.SimpleLocale.Registry`) is suitable
  for projects without complex localization needs. It provides validation and
  display name lookups.

  **Examples:**
  ```iex
  iex> alias Routex.Extension.SimpleLocale.Registry
  iex> Registry.language("nl-BE")
  %{descriptions: ["Dutch", "Flemish"], type: :language}

  iex> Registry.region("nl-BE")
  %{descriptions: ["Belgium"], type: :region}

  iex> Registry.language?("zz")
  false

  iex> Registry.region?("BE")
  true
  ```
  See `Routex.Extension.SimpleLocale.Registry` for more details.


  ## Options

  Options control compile-time route generation and runtime locale detection.

  ### Route Generation Options

  - `locales`: A list of locale definitions. Each entry can be:
    - A locale string (e.g., `"en"`, `"fr-CA"`).
    - A tuple `{locale, attrs}` to override or add attributes for that specific locale branch.

    **Example:**
    ```elixir
    locales: [
      "en", # Standard English
      {"en-GB", %{currency: "GBP"}}, # UK English with specific currency
      "fr"
    ]
    ```

    > #### Attribute Merging Precedence (Compile Time, low to high):
    > 1. Base Derived (from locale string)
    > 2. Explicit Locale Override (from attrs in tuple)
    > 3. Original Branch Attribute (already existing on the branch)
    >
    > SimpleLocale plays well with already configured alternative branches.


  - `default_locale`: The locale for top-level routes (e.g., `/products`).
    Defaults to Gettext's default locale, falling back to `"en"`.

  - `locale_branch_sources`: List of locale (sub)tags to use for generating
     localize routes. Will use the first (sub)tag which returns a non-nil value.
     When no value is found the locale won't have localized routes.

     Note: The `default_locale` is always top-level / is not prefixed.

     Possible values: `:locale` (pass-through), `:region` and/or  `:language`.  
     Default to: `[:language, :region, :locale]`.

     **Examples:**
      ```elixir
      # in configuration
      locales: ["en-001", "fr", "nl-BE"]
      default_locale: "en"  # won't get a prefix as it's the locale of non-branched routes.

      # single source
      locale_branch_sources: :locale => ["en-001", "fr", "nl-BE"],
      locale_branch_sources: :language => ["fr", "nl"],
      locale_branch_sources: :region => ["001", "BE"]

      # with fallback
      locale_branch_sources: [:language, :region] => ["fr", "nl"]
      locale_branch_sources: [:region, :language] => ["001", "fr", "BE"]

      ```

  > #### Tip: Integration with Gettext
  > Synchronize locales with Gettext:
  > ```elixir
  > locales: Gettext.known_locales(MyAppWeb.Gettext),
  > default_locale: Gettext.default_locale(MyAppWeb.Gettext) || "en"
  > ```

  ---

  ### Locale Detection Options

  Runtime detection is configured by specifying sources for locale attributes
  (`:locale`, `:language`, `:region`).

  #### Locale Attributes and Their Sources

  Each attribute (`:locale`, `:language`, `:region`) can have its own list of
  sources and parameter names, where the parameter name is the key to get from
  the source. The parameter should be provided as a string.

  ##### Supported Sources
  - `:accept_language`: From the header sent by the client (e.g. `fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7`)
  - `:assigns`: From conn and socket assigns.
  - `:attrs`: From precompiled route attributes.
  - `:body`: From request body parameters.
  - `:cookie`: From request cookies.
  - `:host`: From the hostname (e.g., `en.example.com`).
  - `:path`: From path parameters (e.g., `/:lang/users`).
  - `:query`: From query parameters (e.g., `?locale=de`).
  - `:session`: From session data.

  ##### Default Configuration

  The default sources for each attribute are:  
  `#{inspect(Routex.Extension.SimpleLocale.Detect.__default_sources__())}`.

  ##### Overriding Detection Behavior

  You can customize sources and parameters per attribute:

  **Examples:**
  ```elixir
  # In your Routex backend module
  locale_sources: [:query, :session, :accept_language], # Order matters
  locale_params: ["locale"], # Look for ?locale=... etc

  language_sources: [:path, :host],
  language_params: ["lang"], # Look for /:lang/... etc

  region_sources: [:attrs] # Only use region from precompiled route attributes
  # region_params defaults to ["region"]
  ```

  ## Configuration examples

  > **Together with...**
  > This extension generates configuration for alternative route branches.
  > To convert these into routes, `Routex.Extension.Alternatives` is automatically
  > enabled when `SimpleLocale` is used.

  > **Integration:**
  > This extension sets runtime attributes (`Routex.Attrs`).
  > To use these attributes in libraries such as Gettext and Cldr, see
  > `Routex.Extension.RuntimeCallbacks`.

  #### Simple Backend Configuration
  This extensions ships with sane default for the most common
  use cases. As a result configuration is only used for overrides.

  **Example:**
  ```elixir
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
      extensions: [
        Routex.Extension.Attrs,
        Routex.Extension.SimpleLocale,
        Routex.Extension.RuntimeCallbacks
          ],
         runtime_callbacks: [
           # Set Gettext locale based on detected language
           {Gettext, :put_locale, [[:attrs, :language]]}
         ]
      ]
  end
  ```

  #### Advanced Backend Configuration
  Due to a fair amount of powerful options, you can tailor the localization to
  custom requirements.

  **Example:**
  ```elixir
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
      extensions: [
        Routex.Extension.Attrs,
        # Enable SimpleLocale for routes and detection
        Routex.Extension.SimpleLocale,
        Routex.Extension.RuntimeCallbacks
       ],
       # Compile-time options
       locales: ["en", "fr", {"nl", %{region_display_name: "Nederland"}}],
       default_locale: "en",
       # Runtime detection overrides
       locale_sources: [:query, :session, :accept_language, :attrs],
       locale_params: ["locale", "lang"],
       language_sources: [:path, :attrs],
       language_params: ["lang"]},
       # Enable callbacks for Gettext/Cldr integration
        {Routex.Extension.RuntimeCallbacks,
         runtime_callbacks: [
           # Set Gettext locale based on detected language
           {Gettext, :put_locale, [[:attrs, :language]]}
            # Set Cldr locale based on detected locale
           {Cldr, :put_locale, [[:attrs, :locale]]}
         ]}
      ]
  end
  ```
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Extension.SimpleLocale.Detect
  alias Routex.Extension.SimpleLocale.Parser
  alias Routex.Extension.SimpleLocale.Registry

  # Alternatives added to extensions in configure/2 and it's configuration created or augmented.
  alias Routex.Extension.Alternatives
  alias Routex.Extension.Alternatives.Branches

  alias Routex.Types, as: T
  alias Routex.Utils

  # Key used for storing locale info in the session.
  @session_key :rtx
  @fallback_locale "en"
  @gettext_locale Application.compile_env(:gettext, :default_locale)
  @locale_fields [:locale, :language, :region]
  @default_route_prefixes [:language, :region, :locale]

  # Typespecs
  @type attrs :: %{optional(atom) => any()}

  @type locale :: String.t()
  @type locale_keys :: :locale | :language | :region
  @type locale_attr_key :: locale_keys | :language_display_name | :region_display_name | atom()
  @type locale_attrs :: %{optional(locale_attr_key()) => any()}
  @type locale_def :: locale() | {locale(), locale_attrs()}
  @type locale_route_prefix :: :locale | :region | :language
  @type locale_branch_sources :: [atom()]

  @type conn :: Plug.Conn.t()
  @type socket :: Phoenix.LiveView.Socket.t()
  @type url :: String.t()
  @type params :: %{optional(String.t()) => any()}
  @type plug_opts :: keyword()

  @impl Routex.Extension
  @spec configure(T.opts(), T.backend()) :: T.opts()
  def configure(config, _backend) do
    default_locale = Keyword.get(config, :default_locale) || @gettext_locale || @fallback_locale
    locales = Keyword.get(config, :locales, [])

    locale_branch_sources =
      config |> Keyword.get(:locale_branch_sources, @default_route_prefixes) |> List.wrap()

    existing_alternatives = Keyword.get(config, :alternatives)

    localized_alternatives =
      create_localized_branches(
        existing_alternatives,
        locales,
        default_locale,
        locale_branch_sources
      )

    config
    |> Keyword.put(:alternatives, localized_alternatives)
    # Ensure Alternatives extension is active to process the generated branches
    |> Keyword.update(:extensions, [Alternatives], fn existing ->
      [Alternatives | existing] |> Enum.uniq()
    end)
  end

  @impl Routex.Extension
  @doc """
  Transforms routes by expanding locale attributes at compile time.

  Ensures each route with a `:locale` attribute also has derived attributes like
  `:language`, `:region`, and their display names, unless already overridden.
  """
  @spec transform(T.routes(), T.backend(), T.env()) :: T.routes()
  def transform(routes, _backend, _env) do
    Enum.map(routes, &expand_route_attrs/1)
  end

  @doc """
  LiveView `handle_params/4` callback hook.

  Detects locale settings based on URL, params, and socket state, then updates
  the socket assigns and Routex attributes.
  """

  @spec handle_params(
          params :: any(),
          url :: any(),
          socket :: socket(),
          extra_attrs :: T.attrs()
        ) :: {:cont, socket()}

  def handle_params(params, url, socket, extra_attrs \\ %{}) do
    uri = URI.new!(url)

    # Simulate parts of the Plug.Conn structure used for detection
    conn_map = %{
      path_params: params,
      query_params: URI.decode_query(uri.query || ""),
      host: uri.host,
      req_headers: [],
      private: socket.private || %{routex: %{}},
      assigns: socket.assigns || %{}
    }

    detected_attrs = Detect.detect_locales(conn_map, [], extra_attrs)
    assign_module = Utils.assign_module()

    socket =
      socket
      |> Attrs.merge(detected_attrs)
      # Assign detected top-level keys (locale, language, region) to socket assigns
      |> assign_module.assign(Map.take(detected_attrs, @locale_fields))

    {:cont, socket}
  end

  @doc """
  Plug callback to detect and assign locale attributes to the connection.

  Examines configured sources (params, session, headers, etc.), updates
  `conn.assigns`, merges attributes into `conn.private.routex.attrs`, and
  persists relevant attributes in the session.
  """
  @spec plug(conn :: conn(), opts :: plug_opts(), extra_attrs :: T.attrs()) :: conn()
  def plug(conn, opts, extra_attrs \\ %{}) do
    conn
    |> update_conn_locales(opts, extra_attrs)
    |> persist_locales_to_session()
  end

  #
  # Private Helper Functions - Compile Time (Branch Generation & Attr Expansion)
  #

  @spec find_locale(locales :: [locale_def()], default :: locale(), locale_branch_sources()) ::
          locale_def()
  defp find_locale(locales, default, locale_branch_sources) do
    Enum.find(locales, default, fn locale_def ->
      extract_locale_string(locale_def, locale_branch_sources) == default
    end)
  end

  # Base case: No alternatives defined, create structure from scratch
  @spec create_localized_branches(
          nil,
          locales :: [locale_def()],
          default_locale :: locale(),
          locale_branch_sources()
        ) :: Branches.branches_nested()
  defp create_localized_branches(nil, locales, default_locale, locale_branch_sources) do
    default_locale_def = find_locale(locales, default_locale, locale_branch_sources)

    # Pass empty map as initial_attrs as there's no parent structure.
    root_attrs = build_locale_attrs(default_locale_def, %{})

    localized_branches =
      for locale_def <- locales,
          locale_str = extract_locale_string(locale_def, locale_branch_sources),
          locale_str != nil,
          locale_str != default_locale,
          into: %{} do
        locale_attrs = build_locale_attrs(locale_def, %{})
        slug = "/" <> locale_str

        {slug, %{attrs: locale_attrs}}
      end

    # Root node "/" contains default attrs and potentially nested localized branches
    root_node_base = %{attrs: root_attrs}

    root_node =
      if map_size(localized_branches) > 0 do
        Map.put(root_node_base, :branches, localized_branches)
      else
        root_node_base
      end

    %{"/" => root_node}
  end

  # Branch existing alternatives structure for each locale.
  @spec create_localized_branches(
          existing_alternatives :: Branches.branches_nested(),
          locales :: [locale_def()],
          default_locale :: locale(),
          locale_branch_sources()
        ) :: Branches.branches_nested()
  defp create_localized_branches(
         existing_alternatives,
         locales,
         default_locale,
         locale_branch_sources
       ) do
    default_locale_def = find_locale(locales, default_locale, locale_branch_sources)

    # Process each top-level slug (like "/" or "/other_root") from the original map
    for {base_slug, original_branch_config} <- existing_alternatives, into: %{} do
      # --- Process the original structure for the DEFAULT locale ---
      # This applies default locale attributes merged with original attributes recursively,
      # ensuring original attributes win where they conflict.
      # Resulting map might or might not have a :branches key.
      default_processed_config =
        apply_locale_to_structure(original_branch_config, default_locale_def)

      # --- Generate branches for ALTERNATE locales ---
      # These branches are based on applying the alternate locale to the ORIGINAL structure.
      alternate_locale_branches =
        for locale_def <- locales,
            locale_str = extract_locale_string(locale_def, locale_branch_sources),
            locale_str != nil,
            locale_str != default_locale,
            into: %{} do
          locale_slug = "/" <> locale_str
          # Apply the alternate locale recursively to the original config for this base_slug,
          # ensuring original attributes win. Result might or might not have :branches.
          localized_config_for_alt_locale =
            apply_locale_to_structure(original_branch_config, locale_def)

          {locale_slug, localized_config_for_alt_locale}
        end

      # --- Combine ---
      # The final structure for the base_slug has:
      # 1. Attributes resulting from applying the default locale processing to the original attributes.
      # 2. Branches = (Original sub-branches processed for default locale) + (New alternate locale branches)

      # Get branches from default processing, defaulting to empty map if key is missing
      default_branches = Map.get(default_processed_config, :branches, %{})
      # Combine with the newly generated alternate locale branches
      combined_branches = Map.merge(default_branches, alternate_locale_branches)

      branch_node_base = %{attrs: default_processed_config.attrs}

      final_branch_config =
        if map_size(combined_branches) > 0 do
          Map.put(branch_node_base, :branches, combined_branches)
        else
          branch_node_base
        end

      {base_slug, final_branch_config}
    end
  end

  # Recursively applies locale attributes to a branch configuration structure,
  #
  # Merges attributes following the precedence:
  # Base Derived < Explicit Locale Override < Original Branch Attribute

  @spec apply_locale_to_structure(original_config :: map(), locale_def :: locale_def()) ::
          Branches.opts_branch()
  defp apply_locale_to_structure(original_config, locale_def) do
    original_attrs = Map.get(original_config, :attrs, %{})
    original_sub_branches = Map.get(original_config, :branches, %{})

    # Calculate attributes derived ONLY from the locale_def (Base + Explicit Override part)
    locale_specific_attrs = build_locale_attrs(locale_def)

    # Merge the original attributes last, so they take precedence over locale_specific_attrs
    # Original wins
    attrs_at_this_level = merge_attrs(locale_specific_attrs, original_attrs)

    # Recursively apply the same logic to all original sub-branches
    localized_sub_branches =
      for {sub_slug, sub_config} <- original_sub_branches, into: %{} do
        {sub_slug, apply_locale_to_structure(sub_config, locale_def)}
      end

    # Start building the result map for this level
    result_base = %{attrs: attrs_at_this_level}

    if map_size(localized_sub_branches) > 0 do
      Map.put(result_base, :branches, localized_sub_branches)
    else
      result_base
    end
  end

  # Builds locale attributes, merging base derived, explicit overrides, and initial attributes.
  # Note: The *caller* (`apply_locale_to_structure`) determines final precedence by how it merges
  # the result of this function with original attributes. This function calculates the combined
  # effect of `initial_attrs`, `base_derived`, and `explicit_overrides`.

  @spec build_locale_attrs(locale_def :: locale_def(), initial_attrs :: locale_attrs()) ::
          locale_attrs()
  defp build_locale_attrs(locale_def, initial_attrs \\ %{})

  # Handle {locale, overrides} tuple
  # Merges: initial < base < overrides
  defp build_locale_attrs({locale_str, overrides}, initial_attrs)
       when is_binary(locale_str) and is_map(overrides) do
    derived_attrs = build_derived_locale_attrs(locale_str)
    # Merge base < overrides
    merged_with_overrides = merge_attrs(derived_attrs, overrides)
    # Merge initial < (base + overrides)
    merge_attrs(initial_attrs, merged_with_overrides)
  end

  # Handle simple locale string
  # Merges: initial < base
  defp build_locale_attrs(locale_str, initial_attrs) when is_binary(locale_str) do
    derived_attrs = build_derived_locale_attrs(locale_str)
    # Merge initial < base
    merge_attrs(initial_attrs, derived_attrs)
  end

  # Helper to get only the derived attributes from a locale string.
  @spec build_derived_locale_attrs(locale :: locale()) :: locale_attrs()
  defp build_derived_locale_attrs(locale_str) when is_binary(locale_str) do
    language = Parser.extract_part(locale_str, :language)
    region = Parser.extract_part(locale_str, :region)

    %{
      locale: locale_str,
      language: language,
      region: region,
      language_display_name: lookup_language_name(language),
      region_display_name: lookup_region_name(region)
    }
  end

  # Helper to expand route attributes with locale fields derived from `locale` when set.
  @spec expand_route_attrs(T.route()) :: T.route()
  defp expand_route_attrs(route) do
    attrs = Attrs.get(route)

    if locale_str = Map.get(attrs, :locale) do
      # Derive values when not explicitly set
      language = Map.get(attrs, :language) || Parser.extract_part(locale_str, :language)
      region = Map.get(attrs, :region) || Parser.extract_part(locale_str, :region)
      lang_display = Map.get(attrs, :language_display_name) || lookup_language_name(language)
      reg_display = Map.get(attrs, :region_display_name) || lookup_region_name(region)

      # Attributes to potentially add/overwrite (nil values from lookups won't overwrite during merge)
      derived_attrs = %{
        language: language,
        region: region,
        language_display_name: lang_display,
        region_display_name: reg_display
      }

      # Merge derived attributes, respecting existing values in attrs.
      updated_attrs = merge_attrs(derived_attrs, attrs)

      Attrs.put(route, updated_attrs)
    else
      route
    end
  end

  @spec lookup_language_name(language :: String.t() | nil) :: String.t() | nil
  defp lookup_language_name(nil), do: nil

  defp lookup_language_name(language) do
    case Registry.language(language) do
      %{descriptions: [desc | _]} -> desc
      _other -> nil
    end
  end

  @spec lookup_region_name(region :: String.t() | nil) :: String.t() | nil
  defp lookup_region_name(nil), do: nil

  defp lookup_region_name(region) do
    case Registry.region(region) do
      %{descriptions: [desc | _]} -> desc
      _other -> nil
    end
  end

  #
  # Private Helper Functions - Runtime (Conn/Socket Update & Session)
  #

  @spec update_conn_locales(conn :: conn(), opts :: plug_opts(), extra_attrs :: T.attrs()) ::
          conn()
  defp update_conn_locales(conn, opts, extra_attrs) do
    # Detect locales using conn, plug opts, and extra_attrs (which contain __backend__)
    # Detect.detect_locales needs to extract config from extra_attrs[:__backend__] if opts are empty
    detected_attrs = Detect.detect_locales(conn, opts, extra_attrs)

    # Update conn.assigns with top-level locale keys
    conn_with_assigns =
      detected_attrs
      |> Map.take(@locale_fields)
      |> Enum.reduce(conn, fn {key, value}, acc_conn ->
        Plug.Conn.assign(acc_conn, key, value)
      end)

    # Update Routex attributes stored in conn.private
    Attrs.merge(conn_with_assigns, detected_attrs)
  end

  @spec persist_locales_to_session(conn :: conn()) :: conn()
  defp persist_locales_to_session(%Plug.Conn{private: %{plug_session: _}} = conn) do
    attrs_to_persist =
      conn
      |> Attrs.get()
      |> Map.take(@locale_fields)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    if map_size(attrs_to_persist) > 0 do
      # Merge detected attrs into existing session data under our key
      session_data = Plug.Conn.get_session(conn, @session_key) || %{}
      updated_session_data = Map.merge(session_data, attrs_to_persist)
      Plug.Conn.put_session(conn, @session_key, updated_session_data)
    else
      conn
    end
  end

  defp persist_locales_to_session(conn) do
    conn |> Plug.Conn.fetch_session() |> persist_locales_to_session()
  end

  @spec extract_locale_string(locale_def(), locale_route_prefix() | locale_branch_sources()) ::
          locale()
  defp extract_locale_string(locale, locale_branch_sources) when is_list(locale_branch_sources) do
    Enum.find_value(locale_branch_sources, fn prefix -> extract_locale_string(locale, prefix) end)
  end

  defp extract_locale_string({locale_str, _attrs}, :locale), do: locale_str

  defp extract_locale_string({locale_str, _attrs}, locale_route_prefix),
    do: Parser.extract_part(locale_str, locale_route_prefix)

  defp extract_locale_string(locale_str, :locale), do: locale_str

  defp extract_locale_string(locale_str, locale_route_prefix) when is_binary(locale_str),
    do: Parser.extract_part(locale_str, locale_route_prefix)

  # Merges two maps. `new_attrs` takes precedence, except when its value is nil.
  @spec merge_attrs(current_attrs :: attrs(), override_attrs :: attrs | nil) ::
          locale_attrs() | attrs()

  defp merge_attrs(existing_attrs, nil) when is_map(existing_attrs), do: existing_attrs

  defp merge_attrs(existing_attrs, new_attrs) when is_map(existing_attrs) and is_map(new_attrs) do
    Map.merge(existing_attrs, new_attrs, fn _key, existing_val, new_val ->
      if is_nil(new_val), do: existing_val, else: new_val
    end)
  end
end
