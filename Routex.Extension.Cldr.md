# `Routex.Extension.Cldr`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/cldr.ex#L1)

Adapter for projects using :ex_cldr. It generates configuration for locale routes
based on your existing Cldr setup for a seamless experience.

 > #### Have a look at.... {: .neutral}
> This adapter was developed before `Routex.Extension.Localize.Phoenix` -a
> powerful localization extension which automatically integrates with your existing Cldr-setup.
> You might also be interested in our guide [Localize Phoenix](/docs/guides/LOCALIZE_PHOENIX.md).

## Interpolating Locale Data

Interpolation is provided by `Routex.Extension.Interpolation`, which
is able to use any `Routex.Attr` for interpolation into your routes.
See it's documentation for additional options.

When using this Cldr extension, the following interpolations are supported as they
are set as `Routex.Attr`:

* `locale` will interpolate the Cldr locale name
* `locale_display` will interpolate the Cldr locale display name
* `language` will interpolate the Cldr language name
* `territory` will interpolate the Cldr territory code

Some examples:
```elixir
preprocess_using ExampleWeb.RoutexBackend do
  scope "/#{territory}/territory/" do
    get "/locale/pages/:page/#{locale}/", PageController, :show
    get "/language/#{language}/pages/:page", PageController, :show
  end
end
```

## Configuration

> #### Ejecting the CLDR extension {: .neutral}
> Using the Cldr adapter provides the advantage of keeping your localized routes
> in sync with the configuration of Cldr. The disadvantage is a lack of flexibility.
> If you ever need more flexibility, you can [eject the Cldr extension](#module-eject-the-cldr-adapter).

```diff
defmodule ExampleWeb.RoutexBackend do
use Routex.Backend,
extensions: [
  # required
   Routex.Extension.AttrGetters,

  # adviced
  Routex.Extension.AlternativeGetters,
  Routex.Extension.Assigns,

  # the adapter with dependency
  Routex.Extension.Cldr,
  Routex.Extension.Alternatives,

  # replacements for cldr-routes
  Routex.Extension.VerifiedRoutes,
  Routex.Extension.Interpolation, #  when using routes with interpolation
  Routex.Extension.Translations,  # when using translated routes

  # replacements for cldr-plugs
  Routex.Extension.LiveViewHooks,
  Routex.Extension.Plugs,
  Routex.Extension.Localize.Phoenix.Runtime,

  # control Cldr locale at runtime
  Routex.Extension.RuntimeDispatcher,
],
+ cldr_backend: MyApp.Cldr,
+ translations_backend: MyApp.Gettext,  #  when using translated routes
+ translations_domain: "routes",  #  when using translated routes
+ alternatives_prefix: false,  #  when using routes with interpolation
+ verified_sigil_routex: "~q", #  consider using ~p, see `Routex.Extension.VerifiedRoutes`
+ dispatch_targets: [
+   # Set CLDR locale from :locale attribute
+   {Cldr, :put_locale, [MyApp.Cldr, [:attrs, :locale]]}
+ ]
end
```

```diff
defmodule ExampleWeb.Router
# require your Cldr backend module before `use`ing the router.
+ require ExampleWeb.Cldr

use ExampleWeb, :router

import ExampleWeb.UserAuth
```

When your application does not compile after adding this extension, force a
recompile using `mix compile --force`.

## Pseudo result
 This extension injects `:alternatives` into your configuration.
 See the documentation of `Routex.Extension.Alternatives` to see
 more options and the pseudo result.

## Eject the Cldr adapter
This extension abstracts away the configuration of `Routex.Extension.Alternatives`. You may want
to customize things beyond what `Routex.Extension.Cldr` provides. When you eject, you copy
the generated configuration into the Routex backend.

In other words, instead of relying on the preconfigured “black box” provided by this extension, you
now have full access to—and responsibility for—the configuration of `Routex.Extension.Alternatives`.

#### Copy the generated configuration into your Routex backend**

Call the `config/0` function on you backend (e.g. `ExampleWeb.RoutexBackend.config()`)
in IEX. Copy the `alternatives: %{...}` section to your Routex backend.

```diff
defmodule ExampleWeb.RoutexBackend do
use Routex.Backend,
extensions: [...],
+ alternatives: %{...}
```

#### Remove references to Cldr

```diff
defmodule ExampleWeb.RoutexBackend do
use Routex.Backend,
extensions: [
-  Routex.Extension.Cldr,
],
- cldr_backend: MyApp.Cldr,
```

```diff
defmodule ExampleWeb.Router
- require ExampleWeb.Cldr

use ExampleWeb, :router

import ExampleWeb.UserAuth
```

## `Routex.Attrs`
**Requires**
- none

**Sets**
- language
- locale
- locale_display
- territory

# `configure`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/cldr.ex#L157)

```elixir
@spec configure(Routex.Types.opts(), Routex.Types.backend()) :: Routex.Types.opts()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
