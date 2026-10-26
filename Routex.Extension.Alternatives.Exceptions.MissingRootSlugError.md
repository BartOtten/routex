# `Routex.Extension.Alternatives.Exceptions.MissingRootSlugError`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternatives/exceptions.ex#L32)

Raised when the branch map does not start with the root branch "/".

```elixir
%{
  branches: %{
    "/first"  =>    %{attrs: %{key1: 1}},
    "/other"  =>    %{attrs: %{key1: 1}}},
}
```

To fix this, include a branch for the root "/".

```elixir
`%{
  branches: %{
    "/" => %{
      attrs: %{level: 1}
      branches: %{
        "/first"  =>    %{attrs: %{level: 2}},
        "/other"  =>    %{attrs: %{level: 2}}
      }
    },
  }
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
