# `Routex.Route`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/route.ex#L1)

Function for working with Routex augmented Phoenix Routes

# `exprs`

```elixir
@spec exprs(Routex.Types.route(), Routex.Types.env()) :: map()
```

Compatibility wrapper around `Phoenix.Router.Route.exprs`

# `get_backends`

```elixir
@spec get_backends(Routex.Types.routes()) :: [Routex.Types.backend()]
```

Returns a list of unique backends

# `get_nesting`

```elixir
@spec get_nesting(Routex.Types.route(), integer()) :: [integer()]
```

Returns the nesting level of an (ancestor) route. By default the parent
(offset: -1). This can be adjusted by providing an negative depth offset.

# `group_by_method_and_origin`

Returns routes grouped by the combination of method and origin path

# `group_by_method_and_path`

```elixir
@spec group_by_method_and_path(Routex.Types.routes(), neg_integer()) :: %{
  required({atom(), binary()}) =&gt; Routex.Types.routes()
}
```

# `group_by_nesting`

```elixir
@spec group_by_nesting(Routex.Types.routes(), neg_integer()) :: %{
  required([integer()]) =&gt; Routex.Types.routes()
}
```

Returns routes grouped by nesting level of an (ancestor) route. By default
groups by parent (offset: -1).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
