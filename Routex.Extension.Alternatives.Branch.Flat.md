# `Routex.Extension.Alternatives.Branch.Flat`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternatives/branches.ex#L20)

Struct for flattened branch

# `t`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternatives/branches.ex#L24)

```elixir
@type t() :: %Routex.Extension.Alternatives.Branch.Flat{
  attrs: %{required(atom()) =&gt; any()} | nil,
  branch_key: binary() | atom(),
  branch_path: [binary()],
  branch_prefix: binary()
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
