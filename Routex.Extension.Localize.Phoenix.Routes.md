# `Routex.Extension.Localize.Phoenix.Routes`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L1)

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
   - A keyword tuple `locale: attrs` with attributes map for that specific locale branch.

   **Example:**
   ```elixir
   locales: [
     # Standard English
     "en",
     # Standard French
     "fr"
     # Language: "English", Region: "Global" displayed as "Worldwide"
     "en-001": %{region_display_name: "Worldwide"},
     # Language: "English", Region: "Great Brittain", Compile time route attributes: %{currency: "GBP"}
     "en-GB": %{currency: "GBP"},
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

# `attributes`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L176)

```elixir
@type attributes() :: %{optional(atom()) =&gt; any()}
```

# `locale`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L177)

```elixir
@type locale() :: String.t()
```

# `locale_attribute_key`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L180)

```elixir
@type locale_attribute_key() :: locale_attribute_keys() | atom()
```

# `locale_attribute_keys`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L178)

```elixir
@type locale_attribute_keys() ::
  :locale | :language | :region | :language_display_name | :region_display_name
```

# `locale_attributes`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L181)

```elixir
@type locale_attributes() :: %{optional(locale_attribute_key()) =&gt; any()}
```

# `locale_definition`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L182)

```elixir
@type locale_definition() :: locale() | {locale(), locale_attributes()}
```

# `prefix_source`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L183)

```elixir
@type prefix_source() ::
  :locale | :region | :language | :language_display_name | :region_display_name
```

# `prefix_sources`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_routes.ex#L185)

```elixir
@type prefix_sources() :: prefix_source() | [prefix_source()]
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
