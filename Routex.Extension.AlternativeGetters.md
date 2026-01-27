# `Routex.Extension.AlternativeGetters`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternative_getters.ex#L1)

Creates helper functions to get a list of maps alternative slugs and their `Routex.Attrs`
by providing a binary url. Sets `match?: true` for the url matching record.

## Configuration
```diff
# file /lib/example_web/routex_backend.ex
defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
    Routex.Extension.AttrGetters, # required
    Routex.Extension.Alternatives,
+   Routex.Extension.AlternativeGetters
],
```

## Usage example
```elixir
<!-- @url is made available by Routex -->
<!-- alternatives/1 is located in ExampleWeb.Router.RoutexHelpers aliased as Routes -->
<.link
   :for={alternative <- Routes.alternatives(@url)}
   class="button"
   rel="alternate"
   hreflang={alternative.attrs.locale}
   patch={alternative.slug}
 >
   <.button class={(alternative.match? && "highlighted") || ""}>
     <%= alternative.attrs.display_name %>
   </.button>
 </.link>
```

## Pseudo result
```elixir
iex> ExampleWeb.Router.RoutexHelpers.alternatives("/products/12?foo=baz")
[ %Routex.Extension.AlternativeGetters{
  slug: "products/12/?foo=baz",
  match?: true,
  attrs: %{
    __branch__: [0, 12, 0],
    __origin__: "/products/:id",
    [...attributes set by other extensions...]
  }},
  %Routex.Extension.AlternativeGetters{
  slug: "/europe/products/12/?foo=baz",
  match?: false,
  attrs: %{
    __branch__: [0, 12, 1],
    __origin__: "/products/:id",
    [...attributes set by other extensions...]
  }},
 %Routex.Extension.AlternativeGetters{
  slug: "/asia/products/12/?foo=baz",
  match?: false,
  attrs: %{
    __branch__: [0, 12, 1],
    __origin__: "/products/:id",
    [...attributes set by other extensions...]
  }},
]
```

## `Routex.Attrs`
**Requires**
- none

**Sets**
- none

## Helpers
- alternatives(url :: String.t()) :: struct()

---

*Consult [api-reference.md](api-reference.md) for complete listing*
