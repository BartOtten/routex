# `Routex.Extension.VerifiedRoutes`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/verified_routes.ex#L1)

Supports the use of original route paths in controllers and templates while rendering
transformed route paths at runtime without performance impact.

> #### Implementation summary {:.info}
> Each sigil and function eventualy delegates to the official
> `Phoenix.VerifiedRoutes`.  If a non-branching route is provided it will
> simply delegate to the official Phoenix function. If a branching route is
> provided, it will use a branching mechanism before delegating.

#### Alternative Verified Route sigil
Provides a sigil (default: `~l`) to verify transformed and/or branching routes.
The sigil to use can be set to `~p` to override the default of Phoenix as
it is a drop-in replacement. If you choose to override the default Phoenix sigil,
it is renamed (default: `~o`) and can be used when unaltered behavior is required.

#### Variants of url/{2,3,4} and path/{2,3}
Provides branching variants of (and delegates to) macro's provided by
`Phoenix.VerifiedRoutes`. Both new macro's detect whether branching should be
applied.

## Options
- `verified_sigil_routex`: Sigil to use for Routex verified routes (default `"~l"`)
- `verified_sigil_phoenix`: Replacement for the native (original) sigil when `verified_sigil_routex`
  is set to "~p". (default: `"~o"`)
 - `verified_url_routex`: Function name to use for Routex verified routes powered `url`. (default: `:rtx_url`)
- `verified_url_phoenix`: Replacement for the native `url` function when `verified_url_routex`
  is set to `:url`. (default: `:phx_url`)
 - `verified_path_routex`: Function name to use for Routex verified routes powered `path` (default `:rtx_path`)
- `verified_path_phoenix`: Replacement for the native `path` function  when `verified_path_routex`
  is set to `:path`. (default: `:phx_path`)

When `verified_sigil_routex` is set to "~p" an additional change must be made.

```diff
# file /lib/example_web.ex
defp routex_helpers do
+  import Phoenix.VerifiedRoutes,
+      except: [sigil_p: 2, url: 1, url: 2, url: 3, path: 2, path: 3]

    import unquote(__MODULE__).Router.RoutexHelpers, only: :macros
    alias unquote(__MODULE__).Router.RoutexHelpers, as: Routes
end
```

## Troubleshoot

#### Warning about unknown branch
The [Verified Routes extension](docs/EXTENSIONS.md#verified-routes) relies on
the availability of the `@url` assignment or the key `:rtx_branch`put
in the process dictionary.

Routex assigns `@url` automatically in `conn` and `socket`, but you need to explicitly
pass it down to components using Verified Routes (example: `<Layouts.app url={@url}>`)

When using a component, make sure :url is a required attribute.

```
attr :url, :string,
  required: true,
  doc: "Required for Routex' Verified Routes: url={@url}"
```

Alternatively, if you don’t mind using process state, you can automatically set the
process key with the [Runtime Dispatcher](docs/EXTENSIONS.md#runtime-dispatcher) extension.

```
+ dispatch_targets: [{Routex.Utils, :process_put_branch, [[:attrs, :__branch__]]}]
```

## Configuration
```diff
# file /lib/example_web/routex_backend.ex
defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
    Routex.Extension.AttrGetters, # required
    Routex.Extension.Alternatives,
    [...]
+   Routex.Extension.VerifiedRoutes
],
+ verified_sigil_routex: "~p",
+ verified_sigil_phoenix: "~o",
+ verified_url_routex: :url,
+ verified_url_phoenix: :url_native,
+ verified_path_routex: :path,
+ verified_path_phoenix: :path_native,
```

## Pseudo result
```elixir
# given Routex behavior is assigned ~l
# given the default behavior is assigned ~o
# given the official macro of Phoenix is assigned ~p

# given another extension has transformed the route
~o"/products/#{product}"   ⇒  ~p"/products/#{products}"
~l"/products/#{product}"   ⇒  ~p"/transformed/products/#{product}"

# given another extension has generated branches / alternative routes
~o"/products/#{product}"  ⇒  ~p"/products/#{products}"
~l"/products/#{product}"  ⇒
        case current_branch do
          nil     ⇒  ~p"/products/#{product}"
          "en"    ⇒  ~p"/products/en/#{product}"
          "eu_nl" ⇒  ~p"/europe/nl/products/#{product}"
          "eu_be" ⇒  ~p"/europe/be/products/#{product}"
        end
```

## `Routex.Attrs`
**Requires**
- none

**Sets**
- none

---

*Consult [api-reference.md](api-reference.md) for complete listing*
