# `Routex.Extension.Alternatives`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/alternatives.ex#L1)

Creates alternative routes based on `branches` configured in a Routex backend
module. Branches can be nested and each branch can provide `Routex.Attrs` to be shared
with other extensions.

> #### In combination with... {: .neutral}
> How to combine this extension for localization is written in de [Localization Guide](guides/LOCALIZE_PHOENIX.md)

## Configuration
```diff
# file /lib/example_web/routex_backend.ex
# This example uses a `Struct` for custom attributes, so there is no attribute inheritance;
# only struct defaults. When using maps, nested branches will inherit attributes from their parent.

+ defmodule ExampleWeb.RoutexBackend.AltAttrs do
+  @moduledoc false
+  defstruct [:contact, locale: "en"]
+ end

defmodule ExampleWeb.RoutexBackend do
+ alias ExampleWeb.RoutexBackend.AltAttrs

use Routex.Backend,
extensions: [
  Routex.Extension.AttrGetters, # required
+ Routex.Extension.Alternatives,
Routex.Extension.AttrGetters
],
+ alternatives: %{
+    "/" => %{
+      attrs: %AltAttrs{contact: "root@example.com"},
+      branches: %{
+        "/europe" => %{
+          attrs: %AltAttrs{contact: "europe@example.com"},
+          branches: %{
+            "/nl" => %{attrs: %AltAttrs{locale: "nl", contact: "verkoop@example.nl"}},
+            "/be" => %{attrs: %AltAttrs{locale: "nl", contact: "handel@example.be"}}
+          }
+        },
+      "/gb" => %{attrs: %AltAttrs{contact: "sales@example.com"}
+    }
+  },
+ alternatives_prefix: false  # whether to automatically prefix routes, defaults to true
```

## Pseudo result
```elixir
    Router              Generated                         Attributes
                        ⇒ /products/:id/edit              locale: "en", contact: "rootexample.com"
    /products/:id/edit  ⇒ /europe/nl/products/:id/edit    locale: "nl", contact: "verkoop@example.nl"
                        ⇒ /europe/be/products/:id/edit    locale: "nl", contact: "handel@example.be"
                        ⇒ /gb/products/:id/edit           locale: "en", contact: "sales@example.com"
 ```

## `Routex.Attrs`
**Requires**
- none

**Sets**
- **any key/value in `:attrs`**
- branch_helper
- branch_alias
- branch_prefix
- branch_opts
- alternatives (list of `Phoenix.Route.Route`)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
