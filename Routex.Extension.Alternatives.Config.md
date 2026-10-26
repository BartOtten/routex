# `Routex.Extension.Alternatives.Config`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternatives/config.ex#L1)

Module to create and validate a Config struct

# `t`

```elixir
@type t() :: %Routex.Extension.Alternatives.Config{
  branches: %{
    required(binary() | nil) =&gt; Routex.Extension.Alternatives.Branch.Flat.t()
  }
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
