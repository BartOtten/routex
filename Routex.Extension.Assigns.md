# `Routex.Extension.Assigns`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/assigns.ex#L1)

Extracts `Routex.Attrs` from a route and makes them available in components
and controllers with the assigns operator `@` (optionally under a namespace).

> #### In combination with... {: .neutral}
> Other extensions set `Routex.Attrs`. The attributes an extension sets is listed in it's documentation.
> To define custom attributes for routes have a look at `Routex.Extension.Alternatives`

## Options
- `namespace`: when set creates a named collection: assigns available as @namespace.key
- `attrs`: If attrs is not set, all Routex.Attrs are included. If attrs is set
  to a list of keys, only the specified subset of attributes will be
  available.

## Configuration
```diff
# file /lib/example_web/routex_backend.ex
defmodule ExampleWeb.RoutexBackend do
  use Routex.Backend,
  extensions: [
    Routex.Extension.AttrGetters, # required
+   Routex.Extension.Assigns
],
+ assigns: %{namespace: :rtx, attrs: [:branch_helper, :locale, :contact, :name]}
```

## Pseudo result
    # in (h)eex template
    @rtx.branch_helper  ⇒  "eu_nl"
    @rtx.locale         ⇒  "nl"
    @rtx.contact        ⇒  "verkoop@example.nl"
    @rtx.name           ⇒  "The Netherlands"

## `Routex.Attrs`
**Requires**
- none

**Sets**
- assigns

## Example use case
Combine with `Routex.Extension.Alternatives` to make compile time, branch
bound assigns available to components and controllers.

# `handle_params`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/assigns.ex#L91)

Hook attached to the `handle_params` stage in the LiveView life cycle

---

*Consult [api-reference.md](api-reference.md) for complete listing*
