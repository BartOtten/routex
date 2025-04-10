defmodule Routex.Extension.SimpleLocale.Beta do
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

  The `:locales`, `:default_locale` and `locale_prefix_sources` options generate localized routes
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

  - `locale_prefix_sources`: List of locale (sub)tags to use for generating
     localize routes. Will use the first (sub)tag which returns a non-nil value.
     When no value is found the locale won't have localized routes.

     Note: The `default_locale` is always top-level / is not prefixed relative to its base.

     Possible values: `:locale`, `:region`, `:language`, `:language_display_name`, `:region_display_name`.
     Default to: `[:language, :region, :locale]`.

     **Examples:**
      ```elixir
      # in configuration
      locales: ["en-001", "fr", "nl-BE"]
      default_locale: "en"  # won't get a prefix as it's the locale of non-branched routes.

      # single source
      locale_prefix_sources: :locale =>   ["/", "/en-001", "/fr", "/nl-be"],
      locale_prefix_sources: :language => ["/", "/fr", "/nl"],
      locale_prefix_sources: :region =>   ["/", "/001", "/be"]
      locale_prefix_sources: :language_display_name =>   ["/", "/english", "/french", "/dutch"]
      locale_prefix_sources: :region_display_name =>   ["/", "/world", "/france", "/belgium"]

      # with fallback
      locale_prefix_sources: [:language, :region] => ["/", "/fr", "/nl"]
      locale_prefix_sources: [:region, :language] => ["/", "/001", "/fr", "/be"]

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
  > This extension generates configuration for alternative route branches under the `:alternatives` key.
  > To convert these into routes, `Routex.Extension.Alternatives` must be enabled and run *after*
  > `SimpleLocale` in the extension list.

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
        Routex.Extension.Alternatives, # Needed to process generated branches
        Routex.Extension.RuntimeCallbacks # Optional: for Gettext/Cldr integration
      ],
      # SimpleLocale options (optional, using defaults)
      # locales: Gettext.known_locales(ExampleWeb.Gettext),
      # default_locale: Gettext.default_locale(ExampleWeb.Gettext),
      # RuntimeCallbacks options
      runtime_callbacks: [
        # Set Gettext locale based on detected language
        {Gettext, :put_locale, [[:attrs, :language]]},
        # Set Cldr locale based on detected locale (if using Cldr)
        # {Cldr, :put_locale, [[:attrs, :locale]]}
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
        # Ensure Alternatives runs *after* SimpleLocale to process generated branches
        Routex.Extension.Alternatives,
        Routex.Extension.RuntimeCallbacks
      ],
      # Compile-time options for SimpleLocale
      locales: ["en", "fr", {"nl", %{region_display_name: "Nederland"}}],
      default_locale: "en",
      locale_prefix_sources: [:language], # Prefix with language code only

      # Runtime detection overrides for SimpleLocale
      locale_sources: [:query, :session, :accept_language, :attrs],
      locale_params: ["locale", "lang"],
      language_sources: [:path, :attrs],
      language_params: ["lang"],

      # Runtime callbacks configuration for RuntimeCallbacks
      runtime_callbacks: [
        # Set Gettext locale based on detected language
        {Gettext, :put_locale, [[:attrs, :language]]},
        # Set Cldr locale based on detected locale
        {Cldr, :put_locale, [[:attrs, :locale]]}
      ]
  end
  ```
  """

  # credo:enable-for-this-file Credo.Check.Readability.ModuleDoc

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Extension.SimpleLocale.Detect
  alias Routex.Extension.SimpleLocale.Parser
  alias Routex.Extension.SimpleLocale.Registry

  # Alternatives extension is needed to process the generated branches.
  alias Routex.Extension.Alternatives
  alias Routex.Extension.Alternatives.Branches

  alias Routex.Types, as: T
  alias Routex.Utils

  # Key used for storing locale info in the session.
  @session_key :rtx
  @fallback_locale "en"
  # Fetch Gettext default at compile time, provide fallback
  @gettext_locale Application.compile_env(:gettext, :default_locale, @fallback_locale)
  @locale_fields [:locale, :language, :region]
  @default_route_prefixes [:language, :region, :locale]

  # Typespecs
  @type attrs :: %{optional(atom()) => any()}

  @type locale :: String.t()
  @type locale_keys ::
          :locale | :language | :region | :language_display_name | :region_display_name
  @type locale_attr_key :: locale_keys() | atom()
  @type locale_attrs :: %{optional(locale_attr_key()) => any()}
  @type locale_def :: locale() | {locale(), locale_attrs()}
  @type locale_prefix_source ::
          :locale | :region | :language | :language_display_name | :region_display_name
  @type locale_prefix_sources :: locale_prefix_source() | [locale_prefix_source()]

  @type conn :: Plug.Conn.t()
  @type socket :: Phoenix.LiveView.Socket.t()
  @type url :: String.t()
  @type params :: %{optional(String.t()) => any()}
  @type plug_opts :: keyword()

  @impl Routex.Extension
  @spec configure(T.opts(), T.backend()) :: T.opts()
  def configure(config, _backend) do
    # Fetch options with defaults
    default_locale = Keyword.get(config, :default_locale, @gettext_locale)
    locales = Keyword.get(config, :locales, [])

    raw_prefix_sources = Keyword.get(config, :locale_prefix_sources, @default_route_prefixes)
    locale_prefix_sources = List.wrap(raw_prefix_sources)

    existing_alternatives = Keyword.get(config, :alternatives)

    # Generate or augment alternative branches based on locales
    localized_alternatives =
      create_localized_branches(
        existing_alternatives,
        locales,
        default_locale,
        locale_prefix_sources
      )

    config
    |> Keyword.put(:alternatives, localized_alternatives)
    |> Keyword.update(:extensions, [Alternatives], fn existing_extensions ->
      # Prepend Alternatives to generate routes
      [Alternatives | existing_extensions] |> Enum.uniq()
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
          params :: map(),
          url :: url(),
          socket :: socket(),
          extra_attrs :: T.attrs()
        ) :: {:cont, socket()}
  def handle_params(params, url, socket, extra_attrs \\ %{}) do
    # Attempt to parse the URL, proceed even if it fails (uri will be nil)
    uri =
      try do
        URI.new!(url)
      rescue
        # Handle cases where url might not be a valid URI string
        _error -> nil
      end

    # Simulate parts of the Plug.Conn structure needed for detection
    conn_map = %{
      # Use path_params from handle_params input
      path_params: params,
      # Safely decode query params
      query_params: (uri && uri.query && URI.decode_query(uri.query)) || %{},
      host: uri && uri.host,
      # No headers available directly, pass empty list
      req_headers: [],
      # Use socket.private and assigns, ensuring defaults
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

  # ============================================================================
  # Private Helper Functions - Compile Time (Branch Generation & Attr Expansion)
  # ============================================================================

  # Finds the locale definition matching the default locale string based on prefix source logic.
  @spec find_locale(locales :: [locale_def()], default :: locale(), locale_prefix_sources()) ::
          locale_def()
  defp find_locale(locales, default, locale_prefix_sources) do
    # Normalize default locale string using the prefix source logic
    default_str_normalized = extract_locale_string(default, locale_prefix_sources)

    Enum.find(locales, default, fn locale_def ->
      # Normalize candidate locale string using the same logic for comparison
      extract_locale_string(locale_def, locale_prefix_sources) == default_str_normalized
    end)

    # If not found, Enum.find/3 returns the default (the `default` locale string),
    # which is acceptable behavior.
  end

  # Calculates the locale prefix based on the locale_def and sources,
  # then puts it into the provided attribute map under the `:prefix` key.
  #
  # If no string representation is found via `extract_locale_string/2`,
  # the original attributes are returned unmodified.
  #
  # Prefixes are generated as "/<normalized_string>" in lowercase.

  @spec put_locale_prefix(
          attrs :: locale_attrs(),
          locale_def :: locale_def(),
          locale_prefix_sources()
        ) :: locale_attrs()
  defp put_locale_prefix(attrs, locale_def, locale_prefix_sources) do
    case extract_locale_string(locale_def, locale_prefix_sources) do
      nil ->
        # No string representation found based on sources (e.g., could be default locale
        # depending on config, or invalid input), return attrs unchanged. Caller handles defaults.
        attrs

      string_repr when is_binary(string_repr) ->
        # Build prefix: lowercase, ensure leading "/"
        prefix = "/" <> String.downcase(string_repr)
        # Add/overwrite :prefix in attrs
        Map.put(attrs, :prefix, prefix)
    end
  end

  # --- Branch Creation Logic ---

  # Base case: No existing alternatives, create structure from scratch.
  @spec create_localized_branches(
          nil,
          locales :: [locale_def()],
          default_locale :: locale(),
          locale_prefix_sources()
        ) :: Branches.branches_nested()
  defp create_localized_branches(nil, locales, default_locale, locale_prefix_sources) do
    default_locale_def = find_locale(locales, default_locale, locale_prefix_sources)

    default_locale_str_normalized =
      extract_locale_string(default_locale_def, locale_prefix_sources)

    # Build attributes for the root ("/") based on the default locale def.
    initial_root_attrs = build_locale_attrs(default_locale_def, %{})
    # Manually set the root prefix to "/" as it's the base.
    # Explicitly set root prefix
    root_attrs = Map.put(initial_root_attrs, :prefix, "/")

    localized_branches =
      for locale_def <- locales,
          locale_str_normalized = extract_locale_string(locale_def, locale_prefix_sources),
          # Only create branches for valid, non-default locales
          locale_str_normalized != nil and locale_str_normalized != default_locale_str_normalized,
          into: %{} do
        # Build base attributes for this locale
        initial_attrs = build_locale_attrs(locale_def, %{})

        # Use the helper to calculate and add the :prefix attribute
        branch_attrs = put_locale_prefix(initial_attrs, locale_def, locale_prefix_sources)

        # Get the prefix *from* the updated attributes to use as the branch key.
        # The guard ensures locale_str_normalized is not nil, so put_locale_prefix added a prefix.
        prefix_key = Map.fetch!(branch_attrs, :prefix)

        {prefix_key, %{attrs: branch_attrs}}
      end

    # Build the root node map
    root_node_base = %{attrs: root_attrs}

    root_node =
      if map_size(localized_branches) > 0 do
        Map.put(root_node_base, :branches, localized_branches)
      else
        root_node_base
      end

    # Return the final structure keyed by the root prefix "/"
    %{"/" => root_node}
  end

  # Recursive case: Branch existing alternatives structure for each locale.
  @spec create_localized_branches(
          existing_alternatives :: Branches.branches_nested(),
          locales :: [locale_def()],
          default_locale :: locale(),
          locale_prefix_sources()
        ) :: Branches.branches_nested()
  defp create_localized_branches(
         existing_alternatives,
         locales,
         default_locale,
         locale_prefix_sources
       ) do
    default_locale_def = find_locale(locales, default_locale, locale_prefix_sources)

    default_locale_str_normalized =
      extract_locale_string(default_locale_def, locale_prefix_sources)

    # Process each top-level prefix (e.g., "/") from the original map
    for {base_prefix, original_branch_config} <- existing_alternatives, into: %{} do
      # 1. Process the original structure for the DEFAULT locale
      #    Applies default locale attrs merged with original attrs (original wins).
      initial_default_processed_config =
        apply_locale_to_structure(original_branch_config, default_locale_def)

      # Ensure the original base_prefix is set correctly on the resulting attributes.
      # Ensure base prefix is retained/set
      default_processed_config =
        put_in(initial_default_processed_config, [:attrs, :prefix], base_prefix)

      # 2. Generate branches for ALTERNATE locales
      alternate_locale_branches =
        for locale_def <- locales,
            locale_str_normalized = extract_locale_string(locale_def, locale_prefix_sources),
            # Only process valid, non-default locales
            locale_str_normalized != nil and
              locale_str_normalized != default_locale_str_normalized,
            into: %{} do
          # Apply the alternate locale recursively to the ORIGINAL config
          localized_config_for_alt_locale =
            apply_locale_to_structure(original_branch_config, locale_def)

          # Get the attributes map possibly modified by apply_locale_to_structure
          current_attrs = Map.get(localized_config_for_alt_locale, :attrs, %{})

          # Use the new helper to calculate and add the locale-specific :prefix attribute
          updated_attrs = put_locale_prefix(current_attrs, locale_def, locale_prefix_sources)

          # Get the calculated prefix for the key.
          # The guard `locale_str_normalized != nil` ensures put_locale_prefix added a prefix.
          prefix_key = Map.fetch!(updated_attrs, :prefix)

          # Put the updated attributes back into the branch config struct
          branch_config = Map.put(localized_config_for_alt_locale, :attrs, updated_attrs)

          {prefix_key, branch_config}
        end

      # 3. Combine
      #    Final structure for base_prefix = default processing + alternate branches

      # Get sub-branches from default processing (if any)
      default_sub_branches = Map.get(default_processed_config, :branches, %{})
      # Combine with the newly generated alternate locale branches
      combined_branches = Map.merge(default_sub_branches, alternate_locale_branches)

      # Build the final config for this base_prefix node
      final_branch_config_base = %{attrs: default_processed_config.attrs}

      final_branch_config =
        if map_size(combined_branches) > 0 do
          Map.put(final_branch_config_base, :branches, combined_branches)
        else
          final_branch_config_base
        end

      {base_prefix, final_branch_config}
    end
  end

  # Recursively applies locale attributes to a branch config structure.
  # Merges attributes respecting precedence: Base Derived < Explicit Locale Override < Original.
  @spec apply_locale_to_structure(original_config :: map(), locale_def :: locale_def()) ::
          Branches.opts_branch()
  defp apply_locale_to_structure(original_config, locale_def) do
    original_attrs = Map.get(original_config, :attrs, %{})
    original_sub_branches = Map.get(original_config, :branches, %{})

    # Calculate attributes derived from the locale_def (Base + Explicit Override)
    locale_specific_attrs = build_locale_attrs(locale_def)

    # Merge: locale_specific_attrs < original_attrs (Original wins)
    attrs_at_this_level = merge_attrs(locale_specific_attrs, original_attrs)

    # Recursively apply to original sub-branches
    localized_sub_branches =
      for {sub_prefix, sub_config} <- original_sub_branches, into: %{} do
        initial_processed_config = apply_locale_to_structure(sub_config, locale_def)
        # Ensure sub-prefix is retained/set
        processed_sub_config = put_in(initial_processed_config, [:attrs, :prefix], sub_prefix)

        {sub_prefix, processed_sub_config}
      end

    # Build the result map for this level
    result_base = %{attrs: attrs_at_this_level}

    if map_size(localized_sub_branches) > 0 do
      Map.put(result_base, :branches, localized_sub_branches)
    else
      result_base
    end
  end

  # --- Attribute Building & Merging ---

  # Builds locale attributes from a locale_def, merging base derived and explicit overrides.
  # Precedence within this function: initial_attrs < base_derived < explicit_overrides.
  # The caller (`apply_locale_to_structure`) handles merging this with original branch attributes.
  @spec build_locale_attrs(locale_def :: locale_def(), initial_attrs :: locale_attrs()) ::
          locale_attrs()
  defp build_locale_attrs(locale_def, initial_attrs \\ %{})

  # Handle {locale, overrides} tuple
  defp build_locale_attrs({locale_str, overrides}, initial_attrs)
       when is_binary(locale_str) and is_map(overrides) do
    derived_attrs = build_derived_locale_attrs(locale_str)
    # Merge order: initial < base < overrides
    initial_attrs
    |> merge_attrs(derived_attrs)
    |> merge_attrs(overrides)
  end

  # Handle simple locale string
  defp build_locale_attrs(locale_str, initial_attrs) when is_binary(locale_str) do
    derived_attrs = build_derived_locale_attrs(locale_str)
    # Merge order: initial < base
    merge_attrs(initial_attrs, derived_attrs)
  end

  # Helper to get derived attributes (:language, :region, display names) from a locale string.
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

  # --- Route Transformation Helper ---

  # Expands route attributes with locale fields derived from :locale if present and not overridden.
  @spec expand_route_attrs(T.route()) :: T.route()
  defp expand_route_attrs(route) do
    attrs = Attrs.get(route)

    case Map.get(attrs, :locale) do
      nil ->
        # No :locale attribute, return route unchanged
        route

      locale_str when is_binary(locale_str) ->
        # Derive base attributes from the :locale string
        base_derived = build_derived_locale_attrs(locale_str)

        # Merge base derived attributes into existing attrs.
        # Existing explicit values (:language, :region, etc.) in `attrs` will take precedence
        # over the `base_derived` ones because `attrs` is the second argument to `merge_attrs`.
        updated_attrs = merge_attrs(base_derived, attrs)

        Attrs.put(route, updated_attrs)

      _invalid_locale ->
        # Locale attribute exists but is not a string? Keep route as is.
        # Optionally log a warning here.
        route
    end
  end

  # --- Registry Lookups ---

  @spec lookup_language_name(language :: String.t() | nil) :: String.t() | nil
  defp lookup_language_name(nil), do: nil

  defp lookup_language_name(language) do
    case Registry.language(language) do
      %{descriptions: [desc | _]} -> desc
      # Language not found or no description
      _miss -> nil
    end
  end

  @spec lookup_region_name(region :: String.t() | nil) :: String.t() | nil
  defp lookup_region_name(nil), do: nil

  defp lookup_region_name(region) do
    case Registry.region(region) do
      %{descriptions: [desc | _]} -> desc
      # Region not found or no description
      _miss -> nil
    end
  end

  # ============================================================================
  # Private Helper Functions - Runtime (Conn/Socket Update & Session)
  # ============================================================================

  # Detects locales and updates connection assigns and Routex private attributes.
  @spec update_conn_locales(conn :: conn(), opts :: plug_opts(), extra_attrs :: T.attrs()) ::
          conn()
  defp update_conn_locales(conn, opts, extra_attrs) do
    # Detect locales using the Detect module
    detected_attrs = Detect.detect_locales(conn, opts, extra_attrs)

    # Update conn.assigns with top-level locale keys (:locale, :language, :region)
    conn_with_assigns =
      detected_attrs
      |> Map.take(@locale_fields)
      # Assign only non-nil detected values to conn.assigns
      |> Enum.reduce(conn, fn {key, value}, acc_conn ->
        # Avoid negated condition
        if is_nil(value) do
          # Don't assign nil
          acc_conn
        else
          Plug.Conn.assign(acc_conn, key, value)
        end
      end)

    # Merge all detected attributes (including display names etc.) into Routex private attrs
    Attrs.merge(conn_with_assigns, detected_attrs)
  end

  # Persists detected locale fields (:locale, :language, :region) to the session.
  @spec persist_locales_to_session(conn :: conn()) :: conn()
  # If session is already fetched
  defp persist_locales_to_session(%Plug.Conn{private: %{plug_session: fetched_session}} = conn)
       when is_map(fetched_session) do
    attrs_to_persist =
      conn
      # Get current Routex attributes
      |> Attrs.get()
      # Select only locale, language, region
      |> Map.take(@locale_fields)
      # Remove keys with nil values
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    if map_size(attrs_to_persist) > 0 do
      # Merge detected attrs into existing session data under @session_key
      session_data = Plug.Conn.get_session(conn, @session_key) || %{}
      updated_session_data = Map.merge(session_data, attrs_to_persist)
      Plug.Conn.put_session(conn, @session_key, updated_session_data)
    else
      # Nothing to persist
      conn
    end
  end

  # If session needs fetching
  defp persist_locales_to_session(conn) do
    # Fetch session first, then call the function clause above
    conn |> Plug.Conn.fetch_session() |> persist_locales_to_session()
  end

  # ============================================================================
  # Private Helper Functions - General Utilities
  # ============================================================================

  # Extracts a specific part (locale, language, region, display names) from a locale_def
  # based on the provided source(s). Used for determining prefix strings.
  @spec extract_locale_string(locale_def(), locale_prefix_sources()) :: locale() | nil
  defp extract_locale_string(locale_def, locale_prefix_sources)
       when is_list(locale_prefix_sources) do
    # Find the first source that yields a non-nil value
    Enum.find_value(locale_prefix_sources, fn source ->
      extract_locale_string(locale_def, source)
    end)
  end

  defp extract_locale_string(locale_def, source) when is_atom(source) do
    # Delegate to specific clauses based on the source atom
    case locale_def do
      {locale_str, _attrs} when is_binary(locale_str) ->
        extract_locale_string_from_string(locale_str, source)

      locale_str when is_binary(locale_str) ->
        extract_locale_string_from_string(locale_str, source)

      _invalid_def ->
        # Invalid locale_def format
        nil
    end
  end

  # --- Helper clauses for extract_locale_string based on source atom ---

  @spec extract_locale_string_from_string(locale :: locale(), locale_prefix_source()) ::
          locale() | nil
  defp extract_locale_string_from_string(locale_str, :locale), do: locale_str

  defp extract_locale_string_from_string(locale_str, :language) do
    Parser.extract_part(locale_str, :language)
  end

  defp extract_locale_string_from_string(locale_str, :region) do
    Parser.extract_part(locale_str, :region)
  end

  defp extract_locale_string_from_string(locale_str, :language_display_name) do
    locale_str
    |> extract_locale_string_from_string(:language)
    |> lookup_language_name()
  end

  defp extract_locale_string_from_string(locale_str, :region_display_name) do
    locale_str
    |> extract_locale_string_from_string(:region)
    |> lookup_region_name()
  end

  # Fallback for unknown source types
  defp extract_locale_string_from_string(_locale_str, _other_source), do: nil

  # Merges two attribute maps. Values from `override_attrs` take precedence,
  # except when the value in `override_attrs` is nil (it keeps existing value).
  @spec merge_attrs(existing_attrs :: attrs(), override_attrs :: attrs() | nil) :: attrs()
  defp merge_attrs(existing_attrs, nil) when is_map(existing_attrs), do: existing_attrs

  defp merge_attrs(existing_attrs, override_attrs)
       when is_map(existing_attrs) and is_map(override_attrs) do
    Map.merge(existing_attrs, override_attrs, fn _key, existing_val, override_val ->
      # If the overriding value is nil, keep the existing value, otherwise take the override.
      if is_nil(override_val), do: existing_val, else: override_val
    end)
  end
end
