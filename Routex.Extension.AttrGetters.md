# `Routex.Extension.AttrGetters`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/attr_getters.ex#L1)

Access route attributes at runtime within your controllers, plugs, or LiveViews
based on the matched route's properties. Uses pattern matching for optimal
performance during runtime.

This extension provides the required `attrs/1` helper function, used by
Routex to assign helper attributes in the generated `on_mount/4` callback.

> #### In combination with... {: .neutral}
> Other extensions set `Routex.Attrs`. The attributes an extension sets is listed in it's documentation.
> To define custom attributes for routes have a look at `Routex.Extension.Alternatives`

## Configuration
```diff
# file /lib/example_web/routex_backend.ex
defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
+   Routex.Extension.AttrGetters,  # required
],
```

## Pseudo result
```elixir
iex> ExampleWeb.Router.RoutexHelpers.attrs("/europe/nl/producten/?foo=baz")
%{
  __branch__: [0, 9, 3],
  __origin__: "/products",
  backend: ExampleWeb.LocalizedRoutes,
  contact: "verkoop@example.nl",
  locale: "nl",
  branch_name: "The Netherlands",
  branch_helper: "europe_nl",
}
```

## `Routex.Attrs`
**Requires**
- none

**Sets**
- none

## Helpers
- attrs(url :: binary) :: map()

---

*Consult [api-reference.md](api-reference.md) for complete listing*
