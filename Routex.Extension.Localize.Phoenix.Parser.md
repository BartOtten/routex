# `Routex.Extension.Localize.Phoenix.Parser`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/parser.ex#L1)

Handles parsing of accept-language headers.
Uses efficient binary pattern matching and follows RFC 5646 BCP 47 language tag format.

# `parse_accept_language`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/parser.ex#L26)

```elixir
@spec parse_accept_language(String.t() | list()) :: [
  Routex.Extension.Localize.Types.locale_entry()
]
```

Parses an accept-language header into a list of locale entries.

## Examples

    iex> parse_accept_language("en-US,fr-FR;q=0.8")
    [
      %{language: "en", region: "US", territory: "US", locale: "en-US", quality: 1.0},
      %{language: "fr", region: "FR", territory: "FR", locale: "fr-FR", quality: 0.8}
    ]

---

*Consult [api-reference.md](api-reference.md) for complete listing*
