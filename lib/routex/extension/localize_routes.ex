defmodule Routex.Extension.Localize.Routes do
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

  ## Build-in Locale Registry

  The built-in locale registry (`Routex.Extension.Localize.Registry`) is suitable
  for projects without complex localization needs. It provides validation and
  display name lookups.

  **Examples:**
  ```iex
  iex> alias Routex.Extension.Localize.Registry
  iex> Registry.language("nl-BE")
  %{descriptions: ["Dutch", "Flemish"], type: :language}

  iex> Registry.region("nl-BE")
  %{descriptions: ["Belgium"], type: :region}

  iex> Registry.language?("zz")
  false

  iex> Registry.region?("BE")
  true
  ```
  See `Routex.Extension.Localize.Registry` for more details.


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
    > Localize plays well with already configured alternative branches.


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
      default_locale: "en"

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

  ## Configuration examples

  > **Together with...**
  > This extension generates configuration for alternative route branches under the `:alternatives` key.
  > To convert these into routes, `Routex.Extension.Alternatives` must be enabled and run *after*
  > `Localize.Beta` in the extension list.

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
        Routex.Extension.Localize.Routes,
        Routex.Extension.RuntimeCallbacks # Optional: for state depending package integration
      ],
      # Localize options (optional, using defaults)
      # locales: Gettext.known_locales(ExampleWeb.Gettext),
      # default_locale: Gettext.default_locale(ExampleWeb.Gettext),
      # RuntimeCallbacks options
      runtime_callbacks: [
        {Gettext, :put_locale, [[:attrs, :language]]},
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
        # Enable Localize (Beta version) for routes and detection
        Routex.Extension.Localize.Routes,
        # Ensure Alternatives runs *after* Localize.Beta to process generated branches
        Routex.Extension.Alternatives,
        Routex.Extension.RuntimeCallbacks
      ],
      # Compile-time options for Localize.Beta
      locales: ["en", "fr", {"nl", %{region_display_name: "Nederland"}}],
      default_locale: "en",
      locale_prefix_sources: [:language],

      # Runtime detection overrides for Localize.Beta
      locale_sources: [:query, :session, :accept_language, :attrs],
      locale_params: ["locale", "lang"],
      language_sources: [:path, :attrs],
      language_params: ["lang"],

      # Runtime callbacks configuration for RuntimeCallbacks
      runtime_callbacks: [
        {Gettext, :put_locale, [[:attrs, :language]]},
        {Cldr, :put_locale, [[:attrs, :locale]]}
      ]
  end
  ```
  """

  @behaviour Routex.Extension

  alias Routex.Attrs
  alias Routex.Extension.Localize.Parser
  alias Routex.Extension.Localize.Registry

  # Used for type specs. Alternatives is used to generate the actual routes so
  # we make sure we use it's types.
  alias Routex.Extension.Alternatives.Branches

  alias Routex.Types, as: T

  @fallback_locale "en"
  @gettext_locale Application.compile_env(:gettext, :default_locale, @fallback_locale)
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

  @deps [Routex.Extension.Alternatives]

  @impl Routex.Extension
  @spec configure(T.opts(), T.backend()) :: T.opts()
  def configure(config, _backend) do
    default_locale = Keyword.get(config, :default_locale, @gettext_locale)
    locales = Keyword.get(config, :locales, [])
    raw_prefix_sources = Keyword.get(config, :locale_prefix_sources, @default_route_prefixes)
    locale_prefix_sources = List.wrap(raw_prefix_sources)
    existing_alternatives = Keyword.get(config, :alternatives)

    localized_alternatives =
      create_localized_branches(
        existing_alternatives,
        locales,
        default_locale,
        locale_prefix_sources
      )

    config
    |> Keyword.put(:alternatives, localized_alternatives)
    |> Keyword.update(:extensions, @deps, &Enum.uniq(@deps ++ &1))
  end

  @impl Routex.Extension
  @doc """
  Ensures each route with a `:locale` attribute also has derived attributes like
  `:language`, `:region`, and their display names, unless already overridden.
  """
  @spec transform(T.routes(), T.backend(), T.env()) :: T.routes()
  def transform(routes, _backend, _env) do
    Enum.map(routes, &expand_route_attrs/1)
  end

  # ============================================================================
  # Private Helper Functions - Compile Time (Branch Generation & Attr Expansion)
  # ============================================================================

  # Finds the locale definition matching the default locale string based on prefix source logic.
  @spec find_locale(locales :: [locale_def()], default :: locale(), locale_prefix_sources()) ::
          locale_def()
  defp find_locale(locales, default, locale_prefix_sources) do
    default_str_normalized = extract_locale_string(default, locale_prefix_sources)

    Enum.find(locales, default, fn locale_def ->
      extract_locale_string(locale_def, locale_prefix_sources) == default_str_normalized
    end)
  end

  # Calculates the locale prefix based on the locale_def and sources,
  # then puts it into the provided attribute map under the `:prefix` key.
  # If no string representation is found, the original attributes are returned unmodified.
  # Prefixes are generated as "/<normalized_string>" in lowercase.
  @spec put_locale_prefix(
          attrs :: locale_attrs(),
          locale_def :: locale_def(),
          locale_prefix_sources()
        ) :: locale_attrs()
  defp put_locale_prefix(attrs, locale_def, locale_prefix_sources) do
    case extract_locale_string(locale_def, locale_prefix_sources) do
      nil ->
        attrs

      string_repr when is_binary(string_repr) ->
        prefix = "/" <> String.downcase(string_repr)
        Map.put(attrs, :prefix, prefix)
    end
  end

  # --- Branch Creation Logic ---

  # Creates alternative branches structure from scratch when none exists.
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

    initial_root_attrs = build_locale_attrs(default_locale_def, %{})
    # Root is always "/"
    root_attrs = Map.put(initial_root_attrs, :prefix, "/")

    localized_branches =
      for locale_def <- locales,
          locale_str_normalized = extract_locale_string(locale_def, locale_prefix_sources),
          locale_str_normalized != nil and locale_str_normalized != default_locale_str_normalized,
          into: %{} do
        initial_attrs = build_locale_attrs(locale_def, %{})
        branch_attrs = put_locale_prefix(initial_attrs, locale_def, locale_prefix_sources)
        prefix_key = Map.fetch!(branch_attrs, :prefix)
        {prefix_key, %{attrs: branch_attrs}}
      end

    root_node_base = %{attrs: root_attrs}

    root_node =
      if map_size(localized_branches) > 0 do
        Map.put(root_node_base, :branches, localized_branches)
      else
        root_node_base
      end

    %{"/" => root_node}
  end

  # Merges locale-specific branches into an existing alternatives structure.
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

    for {base_prefix, original_branch_config} <- existing_alternatives, into: %{} do
      # 1. Process original structure for the DEFAULT locale
      initial_default_processed_config =
        apply_locale_to_structure(original_branch_config, default_locale_def)

      default_processed_config =
        put_in(initial_default_processed_config, [:attrs, :prefix], base_prefix)

      # 2. Generate branches for ALTERNATE locales
      alternate_locale_branches =
        for locale_def <- locales,
            locale_str_normalized = extract_locale_string(locale_def, locale_prefix_sources),
            locale_str_normalized != nil and
              locale_str_normalized != default_locale_str_normalized,
            into: %{} do
          localized_config_for_alt_locale =
            apply_locale_to_structure(original_branch_config, locale_def)

          current_attrs = Map.get(localized_config_for_alt_locale, :attrs, %{})
          updated_attrs = put_locale_prefix(current_attrs, locale_def, locale_prefix_sources)
          prefix_key = Map.fetch!(updated_attrs, :prefix)
          branch_config = Map.put(localized_config_for_alt_locale, :attrs, updated_attrs)
          {prefix_key, branch_config}
        end

      # 3. Combine
      default_sub_branches = Map.get(default_processed_config, :branches, %{})
      combined_branches = Map.merge(default_sub_branches, alternate_locale_branches)
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

  # Recursively applies locale attributes to a branch config structure, respecting precedence.
  @spec apply_locale_to_structure(original_config :: map(), locale_def :: locale_def()) ::
          Branches.opts_branch()
  defp apply_locale_to_structure(original_config, locale_def) do
    original_attrs = Map.get(original_config, :attrs, %{})
    original_sub_branches = Map.get(original_config, :branches, %{})
    locale_specific_attrs = build_locale_attrs(locale_def)
    attrs_at_this_level = merge_attrs(locale_specific_attrs, original_attrs)

    localized_sub_branches =
      for {sub_prefix, sub_config} <- original_sub_branches, into: %{} do
        initial_processed_config = apply_locale_to_structure(sub_config, locale_def)
        processed_sub_config = put_in(initial_processed_config, [:attrs, :prefix], sub_prefix)
        {sub_prefix, processed_sub_config}
      end

    result_base = %{attrs: attrs_at_this_level}

    if map_size(localized_sub_branches) > 0 do
      Map.put(result_base, :branches, localized_sub_branches)
    else
      result_base
    end
  end

  # --- Attribute Building & Merging ---

  # Builds locale attributes from a locale_def, merging base derived and explicit overrides.
  @spec build_locale_attrs(locale_def :: locale_def(), initial_attrs :: locale_attrs()) ::
          locale_attrs()
  defp build_locale_attrs(locale_def, initial_attrs \\ %{})

  defp build_locale_attrs({locale_str, overrides}, initial_attrs)
       when is_binary(locale_str) and is_map(overrides) do
    derived_attrs = build_derived_locale_attrs(locale_str)

    initial_attrs
    |> merge_attrs(derived_attrs)
    |> merge_attrs(overrides)
  end

  defp build_locale_attrs(locale_str, initial_attrs) when is_binary(locale_str) do
    derived_attrs = build_derived_locale_attrs(locale_str)
    merge_attrs(initial_attrs, derived_attrs)
  end

  # Gets derived attributes (:language, :region, display names) from a locale string.
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
        route

      locale_str when is_binary(locale_str) ->
        base_derived = build_derived_locale_attrs(locale_str)
        updated_attrs = merge_attrs(base_derived, attrs)
        Attrs.put(route, updated_attrs)

      _invalid_locale ->
        route
    end
  end

  # --- Registry Lookups ---

  # Looks up the primary display name for a language code.
  @spec lookup_language_name(language :: String.t() | nil) :: String.t() | nil
  defp lookup_language_name(nil), do: nil

  defp lookup_language_name(language) do
    case Registry.language(language) do
      %{descriptions: [desc | _]} -> desc
      _miss -> nil
    end
  end

  # Looks up the primary display name for a region code.
  @spec lookup_region_name(region :: String.t() | nil) :: String.t() | nil
  defp lookup_region_name(nil), do: nil

  defp lookup_region_name(region) do
    case Registry.region(region) do
      %{descriptions: [desc | _]} -> desc
      _miss -> nil
    end
  end

  # ============================================================================
  # Private Helper Functions - General Utilities
  # ============================================================================

  # Extracts a string representation from a locale_def based on the provided source(s).
  @spec extract_locale_string(locale_def(), locale_prefix_sources()) :: locale() | nil
  defp extract_locale_string(locale_def, locale_prefix_sources)
       when is_list(locale_prefix_sources) do
    Enum.find_value(locale_prefix_sources, fn source ->
      extract_locale_string(locale_def, source)
    end)
  end

  defp extract_locale_string(locale_def, source) when is_atom(source) do
    case locale_def do
      {locale_str, _attrs} when is_binary(locale_str) ->
        extract_locale_string_from_string(locale_str, source)

      locale_str when is_binary(locale_str) ->
        extract_locale_string_from_string(locale_str, source)

      _invalid_def ->
        nil
    end
  end

  # --- Helper clauses for extract_locale_string based on source atom ---

  # Extracts a specific part string based on the source type (:locale, :language, etc.)
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

  defp extract_locale_string_from_string(_locale_str, _other_source), do: nil

  # Merges two attribute maps. Values from `override_attrs` take precedence,
  # except when the value in `override_attrs` is nil (it keeps existing value).
  @spec merge_attrs(existing_attrs :: attrs(), override_attrs :: attrs() | nil) :: attrs()
  defp merge_attrs(existing_attrs, nil) when is_map(existing_attrs), do: existing_attrs

  defp merge_attrs(existing_attrs, override_attrs)
       when is_map(existing_attrs) and is_map(override_attrs) do
    Map.merge(existing_attrs, override_attrs, fn _key, existing_val, override_val ->
      if is_nil(override_val), do: existing_val, else: override_val
    end)
  end
end
