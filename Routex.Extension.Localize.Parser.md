# `Routex.Extension.Localize.Parser`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/parser.ex#L1)

Handles parsing of locale strings.
Uses efficient binary pattern matching and follows RFC 5646 BCP 47 language tag format.

# `extract_locale_parts`

```elixir
@spec extract_locale_parts(String.t()) :: {String.t() | nil, String.t() | nil}
```

# `extract_part`

```elixir
@spec extract_part(String.t(), :language | :region) :: String.t() | nil
```

# `parse_locale`

```elixir
@spec parse_locale(String.t()) :: Routex.Extension.Localize.Types.locale_entry() | nil
```

Parses a single locale string into a locale entry.

## Examples

    iex> parse_locale("en-US")
    %{language: "en", region: "US", territory: "US", locale: "en-US", quality: 1.0}

    iex> parse_locale("fra")
    %{language: "fra", region: nil, territory: nil, locale: "fra", quality: 1.0}

    iex> parse_locale("")
    nil

---

*Consult [api-reference.md](api-reference.md) for complete listing*
