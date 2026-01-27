# `Routex.Extension.Localize.Types`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/types.ex#L1)

Type definitions for locale detection.

# `locale_entry`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/types.ex#L10)

```elixir
@type locale_entry() :: %{
  language: String.t(),
  region: String.t(),
  territory: String.t(),
  locale: String.t()
}
```

# `locale_key`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/types.ex#L6)

```elixir
@type locale_key() :: :region | :language | :territory | :locale
```

# `locale_result`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/types.ex#L8)

```elixir
@type locale_result() :: %{required(locale_key()) =&gt; String.t() | nil}
```

# `source`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/types.ex#L7)

```elixir
@type source() ::
  :accept_language
  | :body
  | :cookie
  | :host
  | :path
  | :query
  | :attrs
  | :session
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
