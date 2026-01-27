# `Routex.Extension.RouteHelpers`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/route_helpers.ex#L1)

This module provides route helpers that support the automatic selection of
alternative routes. These helpers can serve as drop-in replacements for
Phoenix's default route helpers.

Use this extension only if your application leverages extensions that
generate alternative routes. Otherwise, the result will be identical to the
official helpers provided by Phoenix.

## Configuration

In versions of Phoenix prior to 1.7, an alias `Routes` was created by
default. You can either replace this alias or add an alias for
`RoutexHelpers`. Note that Phoenix 1.7 and later have deprecated these
helpers in favor of Verified Routes.

In the example below, we override the default `Routes` alias to use Routex's
Route Helpers as a drop-in replacement, while keeping the original helper
functions available under the alias `OriginalRoutes`:

```diff
# file /lib/example_web.ex
defp routex_helpers do
+ alias ExampleWeb.Router.Helpers, as: OriginalRoutes
+ alias ExampleWeb.Router.RoutexHelpers, as: Routes
end
```

## Pseudo Result

When alternative routes are created, auto-selection is used to keep the user
within a specific branch.

### Example in a (h)eex template:

```heex
<a href={Routes.product_index_path(@socket, :show, product)}>Product #1</a>
```

### Result after compilation:

```elixir
case alternative do
   nil ⇒  "/products/#{product}"
  "en" ⇒  "/products/#{product}"
  "nl" ⇒  "/europe/nl/products/#{product}"
  "be" ⇒  "/europe/be/products/#{product}"
end
```

## `Routex.Attrs`

**Requires:**
- None

**Sets:**
- None

# `helper_module`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/route_helpers.ex#L68)

```elixir
@type helper_module() :: module()
```

# `create_helpers`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/route_helpers.ex#L86)

```elixir
@spec create_helpers(
  Routex.Types.routes(),
  Routex.Types.backend(),
  Routex.Types.env()
) ::
  Routex.Types.ast()
```

Creates the route helpers for the given routes if the `:phoenix_helpers`
attribute is set.

## Parameters
- `routes`: The list of routes to create helpers for.
- `backend`: The backend module (not used).
- `env`: The macro environment.

## Returns
A list of quoted expressions representing the generated helpers.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
