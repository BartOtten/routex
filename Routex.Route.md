# `Routex.Route`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/route.ex#L1)

Function for working with Routex augmented Phoenix Routes

# `exprs`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/route.ex#L72)

```elixir
@spec exprs(Routex.Types.route(), Routex.Types.env()) :: map()
```

Compatibility wrapper around `Phoenix.Router.Route.exprs`

# `get_backends`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/route.ex#L16)

```elixir
@spec get_backends(Routex.Types.routes()) :: [Routex.Types.backend()]
```

Returns a list of unique backends

# `get_nesting`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/route.ex#L25)

```elixir
@spec get_nesting(Routex.Types.route(), integer()) :: [integer()]
```

Returns the nesting level of an (ancestor) route. By default
the parent. This can be adjusted by providing an negative depth offset.

# `group_by_method_and_origin`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/route.ex#L59)

Returns routes grouped by the combination of method and origin path

# `group_by_method_and_path`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/route.ex#L49)

```elixir
@spec group_by_method_and_path(Routex.Types.routes(), integer()) :: %{
  required({atom(), binary()}) =&gt; Routex.Types.routes()
}
```

# `group_by_nesting`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/route.ex#L35)

```elixir
@spec group_by_nesting(Routex.Types.routes(), integer()) :: %{
  required([integer()]) =&gt; Routex.Types.routes()
}
```

Returns routes grouped by nesting level of an (ancestor) route. By default
groups by parent. This can be adjusted by providing an negative depth offset

---

*Consult [api-reference.md](api-reference.md) for complete listing*
