defmodule Routex.Extension.Localize.Phoenix.Routes do
  @moduledoc """
  Localize Phoenix routes using simple configuration.

  At compile time, this extension generates localized routes based on locale
  tags. These locale tags are automatically derived from your Cldr, Gettext or
  Fluent setup and can be overriden using the extensions options.

  When using a custom configuration, tags are validated using a
  [build-in locale registry](Routex.Extension.Localize.Registry)
  based on the authoritive
  [IANA Language Subtag Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry).

  ## Automated locale expansion

  At compile time this extension will expand a routes `:locale` attribute into
  multiple locale attributes using the build-in registry:

  - `:locale` (e.g., "en-US")
  - `:language` (e.g., "en")
  - `:region` (e.g., "US")
  - `:language_display_name` (e.g., "English")
  - `:region_display_name` (e.g., "United States")

  ## Options

  - `locales`: A list of locale definitions. Defaults to known locales
     by Cldr, Gettext or Fluent (in that order).

     Each entry can be:
     - A locale tag (e.g., `"en"`, `"fr-CA"`).
     - A tuple `{locale, attrs}` with attributes map for that specific locale branch.

     **Example:**
     ```elixir
     locales: [
       # Standard English
       "en",
       # Language: "English", Region: "Global" displayed as "Worldwide"
       {"en-001", %{region_display_name: "Worldwide"}
       # Language: "English", Region: "Great Brittain", Compile time route attributes: %{currency: "GBP"}
       {"en-GB", %{currency: "GBP"}},
       # Standard French
       "fr"
     ]
     ```

     > #### Attribute Merging Precedence (Compile Time, low to high):
     > 1. Derived from locale string
     > 2. Explicit Locale Override (from attrs in tuple)
     > 3. Original Branch Attribute (already existing on the branch)
     >
     > Point 3 ensures this extension plays well with
     > pre-configured alternative branches.

  - `default_locale`: The locale for top-level routes (e.g., `/products`).
     Default to the default locale of Cldr, Gettext or Fluent (in that order) with
     fallback to "en".

  - `locale_backend`: Backend to use for Cldr, Gettext or Fluent. Defaults to their
     own backend module name convensions.

  - `locale_prefix_sources`: Single atom or list of locale attributes to prefix
     routes with. Will use the first (sub)tag which returns a non-nil value.
     When no value is found the locale won't have localized routes.

     Possible values: `:locale`, `:region`, `:language`, `:language_display_name`, `:region_display_name`.
     Default to: `[:language, :region, :locale]`.

     **Examples:**
      ```elixir
      # in configuration
      locales: ["en-001", "fr", "nl-NL", "nl-BE"]
      default_locale: "en"

      # single source
      locale_prefix_sources: :locale =>     ["/", "/en-001", "/fr", "/nl/nl", "/nl-be"],
      locale_prefix_sources: :language => ["/", "/fr", "/nl"],
      locale_prefix_sources: :region =>     ["/", "/001", "/nl", "/be"]
      locale_prefix_sources: :language_display_name =>     ["/", "/english", "/french", "/dutch"]
      locale_prefix_sources: :region_display_name =>     ["/", "/world", "/france", "/netherlands", "/belgium"]

      # with fallback
      locale_prefix_sources: [:language, :region] => ["/", "/fr", "/nl"]
      locale_prefix_sources: [:region, :language] => ["/", "/001", "/fr", "/nl", "/be"]

      ```

  ## Configuration examples

  > **Together with...**
  > This extension generates configuration for alternative route branches under the `:alternatives` key.
  > To convert these into routes, `Routex.Extension.Alternatives` is automatically enabled.

  > **Integration:**
  > This extension sets runtime attributes (`Routex.Attrs`).
  > To use these attributes in libraries such as Gettext and Cldr, see
  > `Routex.Extension.RuntimeDispatcher`.

  #### Simple Backend Configuration
  This extensions ships with sane default for the most common
  use cases. As a result configuration is only used for overrides.

  **Example:**
  ```elixir
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
      extensions: [
        Routex.Extension.Attrs,
        Routex.Extension.Localize.Phoenix.Routes,
        Routex.Extension.RuntimeDispatcher # Optional: for state depending package integration
      ],
      # This option is shared with the Translations extension
       :translations_backend: ExampleWeb.Gettext,
      # RuntimeDispatcher options
      dispatch_targets: [
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
        # Enable Localize for localized routes
        Routex.Extension.Localize.Phoenix.Routes,
        Routex.Extension.RuntimeDispatcher
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

      # Runtime dispatch targets used by RuntimeDispatcher
      dispatch_targets: [
        {Gettext, :put_locale, [[:attrs, :language]]},
        {Cldr, :put_locale, [[:attrs, :locale]]}
      ]
  end
  ```
  """
  @behaviour Routex.Extension

  # other extenions
  alias Routex.Attrs
  alias Routex.Extension.Alternatives.Branches

  # submodules
  alias Routex.Extension.Localize.Integrate
  alias Routex.Extension.Localize.Parser
  alias Routex.Extension.Localize.Registry

  # typing
  alias Routex.Types, as: T

  require Integrate

  @default_route_prefix_sources [:language, :region, :locale]

  @type attributes :: %{optional(atom()) => any()}
  @type locale :: String.t()
  @type locale_attribute_keys ::
          :locale | :language | :region | :language_display_name | :region_display_name
  @type locale_attribute_key :: locale_attribute_keys() | atom()
  @type locale_attributes :: %{optional(locale_attribute_key()) => any()}
  @type locale_definition :: locale() | {locale(), locale_attributes()}
  @type prefix_source ::
          :locale | :region | :language | :language_display_name | :region_display_name
  @type prefix_sources :: prefix_source() | [prefix_source()]

  @deps [Routex.Extension.Alternatives]

  @impl Routex.Extension
  @spec configure(T.opts(), T.backend()) :: T.opts()
  def configure(config, backend) do
    existing_alternatives = Keyword.get(config, :alternatives)

    locale_backend = Keyword.get(config, :locale_backend)
    opt_default_locale = Keyword.get(config, :default_locale)
    opt_locales = Keyword.get(config, :locales)

    prefix_sources =
      config
      |> Keyword.get(:locale_prefix_sources, @default_route_prefix_sources)
      |> List.wrap()

    {detected_library, detected_known_locales, detected_default} =
      Integrate.auto_detect(locale_backend)

    detected_locales = [detected_default | detected_known_locales]

    locales = (opt_locales || detected_locales) |> stringify_locales()
    default_locale = (opt_default_locale || detected_default) |> stringify_locales()

    locale_source_info = determine_source_info(opt_locales, backend, detected_library)
    Routex.Utils.print(__MODULE__, ["using locales ", locale_source_info])

    default_source_info = determine_source_info(opt_default_locale, backend, detected_library)
    Routex.Utils.print(__MODULE__, ["using default_locale ", default_source_info])

    localized_branches =
      create_localized_branches(
        existing_alternatives,
        locales,
        default_locale,
        prefix_sources
      )

    config
    |> Keyword.put(:alternatives, localized_branches)
    |> Keyword.update(:extensions, @deps, &Enum.uniq(@deps ++ &1))
  end

  @impl Routex.Extension
  @spec transform(T.routes(), T.backend(), T.env()) :: T.routes()
  def transform(routes, _backend, _env) do
    Enum.map(routes, &expand_route_attributes/1)
  end

  # Determines the source information string based on whether an option was explicitly provided.
  defp determine_source_info(option_value, backend, detected_library) do
    if option_value do
      "as specified in #{to_string(backend)}"
    else
      "detected via #{to_string(detected_library)}"
    end
  end

  @spec find_locale(locales :: [locale_definition()], default :: locale(), prefix_sources()) ::
          locale_definition()
  defp find_locale(locales, default, prefix_sources) do
    default_normalized_string = extract_locale_string(default, prefix_sources)

    Enum.find(locales, default, fn locale_definition ->
      extract_locale_string(locale_definition, prefix_sources) == default_normalized_string
    end)
  end

  defp stringify_locales(locales) when is_list(locales) do
    Enum.map(locales, fn
      locale when is_binary(locale) ->
        locale

      locale when is_atom(locale) ->
        to_string(locale)

      {locale, %{} = attrs} ->
        {to_string(locale), attrs}

      %{} = tag ->
        [tag.language, "-", tag.territory] |> Enum.join()
        # credo:disable-for-next-line
        # TODO: properly use the expression below without depending on Cldr
        # Cldr.LanguageTag.to_string(locale)
    end)
  end

  defp stringify_locales(locale) do
    to_string(locale)
  end

  @spec put_locale_prefix(
          attributes :: locale_attributes(),
          locale_definition :: locale_definition(),
          prefix_sources()
        ) :: locale_attributes()
  defp put_locale_prefix(attributes, locale_definition, prefix_sources) do
    case extract_locale_string(locale_definition, prefix_sources) do
      nil ->
        attributes

      string_repr when is_binary(string_repr) ->
        prefix = "/" <> String.downcase(string_repr)
        Map.put(attributes, :prefix, prefix)
    end
  end

  @spec create_localized_branches(
          nil,
          locales :: [locale_definition()],
          default_locale :: locale(),
          prefix_sources()
        ) :: Branches.branches_nested()
  defp create_localized_branches(nil, locales, default_locale, prefix_sources) do
    default_locale_definition = find_locale(locales, default_locale, prefix_sources)

    default_normalized_string =
      extract_locale_string(default_locale_definition, prefix_sources)

    initial_root_attributes = build_locale_attributes(default_locale_definition, %{})
    root_attributes = Map.put(initial_root_attributes, :prefix, "/")

    localized_branches =
      for locale_definition <- locales,
          normalized_string = extract_locale_string(locale_definition, prefix_sources),
          normalized_string != nil and normalized_string != default_normalized_string,
          into: %{} do
        initial_attributes = build_locale_attributes(locale_definition, %{})

        branch_attributes =
          put_locale_prefix(initial_attributes, locale_definition, prefix_sources)

        prefix = Map.fetch!(branch_attributes, :prefix)
        {prefix, %{attrs: branch_attributes}}
      end

    base_root_node = %{attrs: root_attributes}

    root_node =
      if map_size(localized_branches) > 0 do
        Map.put(base_root_node, :branches, localized_branches)
      else
        base_root_node
      end

    %{"/" => root_node}
  end

  @spec create_localized_branches(
          existing_alternatives :: Branches.branches_nested(),
          locales :: [locale_definition()],
          default_locale :: locale(),
          prefix_sources()
        ) :: Branches.branches_nested()
  defp create_localized_branches(
         existing_alternatives,
         locales,
         default_locale,
         prefix_sources
       ) do
    default_locale_definition = find_locale(locales, default_locale, prefix_sources)

    default_normalized_string =
      extract_locale_string(default_locale_definition, prefix_sources)

    for {base_prefix, original_config} <- existing_alternatives, into: %{} do
      initial_default_config =
        apply_locale_to_structure(original_config, default_locale_definition)

      default_config =
        put_in(initial_default_config, [:attrs, :prefix], base_prefix)

      alternate_branches =
        for locale_definition <- locales,
            normalized_string = extract_locale_string(locale_definition, prefix_sources),
            normalized_string != nil and
              normalized_string != default_normalized_string,
            into: %{} do
          localized_config =
            apply_locale_to_structure(original_config, locale_definition)

          current_attributes = Map.get(localized_config, :attrs, %{})

          updated_attributes =
            put_locale_prefix(current_attributes, locale_definition, prefix_sources)

          prefix = Map.fetch!(updated_attributes, :prefix)
          config = Map.put(localized_config, :attrs, updated_attributes)
          {prefix, config}
        end

      default_branches = Map.get(default_config, :branches, %{})
      combined_branches = Map.merge(default_branches, alternate_branches)
      base_final_config = %{attrs: default_config.attrs}

      final_config =
        if map_size(combined_branches) > 0 do
          Map.put(base_final_config, :branches, combined_branches)
        else
          base_final_config
        end

      {base_prefix, final_config}
    end
  end

  @spec apply_locale_to_structure(
          original_config :: map(),
          locale_definition :: locale_definition()
        ) ::
          Branches.opts_branch()
  defp apply_locale_to_structure(original_config, locale_definition) do
    original_attributes = Map.get(original_config, :attrs, %{})
    original_branches = Map.get(original_config, :branches, %{})
    locale_attributes = build_locale_attributes(locale_definition)
    attributes = merge_attributes(locale_attributes, original_attributes)

    localized_branches =
      for {sub_prefix, sub_config} <- original_branches, into: %{} do
        initial_config = apply_locale_to_structure(sub_config, locale_definition)
        processed_config = put_in(initial_config, [:attrs, :prefix], sub_prefix)
        {sub_prefix, processed_config}
      end

    base_result = %{attrs: attributes}

    if map_size(localized_branches) > 0 do
      Map.put(base_result, :branches, localized_branches)
    else
      base_result
    end
  end

  @spec build_locale_attributes(
          locale_definition :: locale_definition(),
          initial_attributes :: locale_attributes()
        ) ::
          locale_attributes()
  defp build_locale_attributes(locale_definition, initial_attributes \\ %{})

  defp build_locale_attributes({locale, overrides}, initial_attributes)
       when is_binary(locale) and is_map(overrides) do
    derived_attributes = build_derived_locale_attributes(locale)

    initial_attributes
    |> merge_attributes(derived_attributes)
    |> merge_attributes(overrides)
  end

  defp build_locale_attributes(locale, initial_attributes) when is_binary(locale) do
    derived_attributes = build_derived_locale_attributes(locale)
    merge_attributes(initial_attributes, derived_attributes)
  end

  @spec build_derived_locale_attributes(locale :: locale()) :: locale_attributes()
  defp build_derived_locale_attributes(locale) when is_binary(locale) do
    language = Parser.extract_part(locale, :language)
    region = Parser.extract_part(locale, :region)

    %{
      locale: locale,
      language: language,
      region: region,
      language_display_name: lookup_language_name(language),
      region_display_name: lookup_region_name(region)
    }
  end

  @spec expand_route_attributes(T.route()) :: T.route()
  defp expand_route_attributes(route) do
    attributes = Attrs.get(route)

    case Map.get(attributes, :locale) do
      nil ->
        route

      locale when is_binary(locale) ->
        derived_attributes = build_derived_locale_attributes(locale)
        updated_attributes = merge_attributes(derived_attributes, attributes)
        Attrs.put(route, updated_attributes)

      _other ->
        route
    end
  end

  @spec lookup_language_name(language :: String.t() | nil) :: String.t() | nil
  defp lookup_language_name(nil), do: nil

  defp lookup_language_name(language) do
    case Registry.language(language) do
      %{descriptions: [desc | _other_desc]} -> desc
      _other -> nil
    end
  end

  @spec lookup_region_name(region :: String.t() | nil) :: String.t() | nil
  defp lookup_region_name(nil), do: nil

  defp lookup_region_name(region) do
    case Registry.region(region) do
      %{descriptions: [desc | _other_desc]} -> desc
      _other -> nil
    end
  end

  @spec extract_locale_string(locale_definition(), prefix_sources()) :: locale() | nil
  defp extract_locale_string(locale_definition, prefix_sources)
       when is_list(prefix_sources) do
    Enum.find_value(prefix_sources, fn source ->
      extract_locale_string(locale_definition, source)
    end)
  end

  defp extract_locale_string(locale_definition, source) when is_atom(source) do
    case locale_definition do
      {locale, _attrs} when is_binary(locale) ->
        extract_locale_from_string(locale, source)

      locale when is_binary(locale) ->
        extract_locale_from_string(locale, source)

      _other ->
        nil
    end
  end

  @spec extract_locale_from_string(locale :: locale(), prefix_source()) ::
          locale() | nil
  defp extract_locale_from_string(locale, :locale), do: locale

  defp extract_locale_from_string(locale, :language) do
    Parser.extract_part(locale, :language)
  end

  defp extract_locale_from_string(locale, :region) do
    Parser.extract_part(locale, :region)
  end

  defp extract_locale_from_string(locale, :language_display_name) do
    locale
    |> extract_locale_from_string(:language)
    |> lookup_language_name()
  end

  defp extract_locale_from_string(locale, :region_display_name) do
    locale
    |> extract_locale_from_string(:region)
    |> lookup_region_name()
  end

  defp extract_locale_from_string(_locale, _other_source), do: nil

  @spec merge_attributes(existing :: attributes(), overrides :: attributes() | nil) ::
          attributes()
  defp merge_attributes(existing, nil) when is_map(existing), do: existing

  defp merge_attributes(existing, overrides)
       when is_map(existing) and is_map(overrides) do
    Map.merge(existing, overrides, fn _key, existing_value, override_value ->
      if is_nil(override_value), do: existing_value, else: override_value
    end)
  end
end
