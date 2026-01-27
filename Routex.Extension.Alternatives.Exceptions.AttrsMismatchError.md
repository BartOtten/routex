# `Routex.Extension.Alternatives.Exceptions.AttrsMismatchError`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternatives/exceptions.ex#L4)

Raised when the custom attributes of branches do not have the same keys.

```elixir
%{
  branches: %{
    "/"      => %{attrs: %{key1: 1, key2: 2}},
    "/other" => %{attrs: %{key1: 1}} # missing :key2
  }
}
```

To fix this, make the attribute maps consistent or use an attributes struct.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
