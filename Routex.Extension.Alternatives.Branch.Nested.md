# `Routex.Extension.Alternatives.Branch.Nested`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternatives/branches.ex#L1)

Struct for branch with optionally nested branches

# `t`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternatives/branches.ex#L5)

```elixir
@type t() :: %Routex.Extension.Alternatives.Branch.Nested{
  attrs: %{required(atom()) =&gt; any()} | nil,
  branch_key: binary() | atom(),
  branch_path: [binary()],
  branch_prefix: binary(),
  branches: %{required(binary() | atom()) =&gt; t()} | nil
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
