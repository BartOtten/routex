# `Routex.Extension.Interpolation`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/interpolation.ex#L1)

A route may be defined with a routes `Routex.Attrs` interpolated
into it. These interpolations are specified using the usual `#{variable}`
interpolation syntax. Unlike some other routing solutions, interpolation
is *not* restricted to the beginning of routes.

> #### In combination with... {: .neutral}
> Other extensions set `Routex.Attrs`. The attributes an extension sets is listed in it's documentation.
> To define custom attributes for routes have a look at `Routex.Extension.Alternatives`
>
> When using `Routex.Extension.Alternatives` you might
> want to disable auto prefixing for the whole Routex backend (see
> `Routex.Extension.Alternatives`) or per route (see `Routex`).

> #### Bare base route {: .warning}
> The route as specified in the Router will be stripped from any
> interpolation syntax. This allows you to use routes without interpolation
> syntax in your templates (e.g. ~p"/products") and have them verified by
> Verified Routes. The routes will be rendered with interpolated attributes
> at run time.

## Configuration

none

## Usage
```elixir
# file /lib/example_web/routes.ex
live "/products/#{locale}/:id", ProductLive.Index, :index
```

## Pseudo result
 ```elixir
    # in combination with Routex.Extension.Alternatives with auto prefix
    # disabled and 3 branches. It splits the routes and sets the :locale
    # attribute which is used for interpolation.

    Route                      Generated
                               ⇒ /products/en/:id
    /products/#{locale}/:id/   ⇒ /products/fr/:id
                               ⇒ /products/fr/:id
```

## `Routex.Attrs`
**Requires**
- none

**Sets**
- none

---

*Consult [api-reference.md](api-reference.md) for complete listing*
