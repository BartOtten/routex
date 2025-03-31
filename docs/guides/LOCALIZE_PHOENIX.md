# Localize Phoenix with Routex

A core feature of Routex is to enable Phoenix localization. Optionally with
translated URLs; enhancing user engagement, Search Engine Optimization (SEO) and
content relevance.

In this tutorial we will explain how multiple extensions are combined to...
- have a product page with locale URL's.
- use translated routes.
- using automatically localized verified routes.
- control content localization with libraries such as Gettext, Fluent and Cldr.
- display links to other locales.

All without changing a single route in your templates!

> #### But first... {: .neutral}
> This tutorial assumes that you’ve already set up Routex by following the [usage
> guide](USAGE.md). Although the default configuration provided there is nearly
> complete, we walk through each individual step so you can see how all the parts
> integrate.


In the end we will have multiple localized (and translated) routes *and* the language used
by Gettext is set to the language of the route.

                        ⇒ /products/:id/edit                    @loc.language = "en"
    /products/:id/edit  ⇒ /eu/nederland/producten/:id/bewerken  @loc.language = "nl"
                        ⇒ /eu/france/producto/:id/editar        @loc.language = "fr"
                        ⇒ /gb/products/:id/edit                 @loc.language = "en"


Feel free to [open a topic at Elixir Forums](https://elixirforum.com/tag/routex)
when you need help with this tutorial. When you are certain you encounter a bug
please create an issue at GitHub.


## What we start with
This tutorial uses an example Router with multiple routes to the product page.
The route.ex file contains something like the example below.

      preprocess_using ExampleWeb.RoutexBackend do
        scope "/", ExampleWeb do
          pipe_through :browser

          live "/products", ProductLive.Index, :index
          live "/products/new", ProductLive.Index, :new
          live "/products/:id/edit", ProductLive.Index, :edit
          live "/products/:id", ProductLive.Show, :show
          live "/products/:id/show/edit", ProductLive.Show, :edit
        end
      end

When you run `mix phx.routes` you will see those routes as:

    product_show_path  GET     /products/:id/show/edit                ExampleWeb.ProductLive.Show :edit
    product_show_path  GET     /products/:id                          ExampleWeb.ProductLive.Show :show
    product_index_path  GET    /products/:id/edit                     ExampleWeb.ProductLive.Index :edit
    product_index_path  GET    /products/new                          ExampleWeb.ProductLive.Index :new
    product_index_path  GET    /products                              ExampleWeb.ProductLive.Index :index

You want these pages to be accessible from multiple (translated) URLs.

## Step 1: Generate alternative URLs

The `Routex.Extension.Alternatives` generates alternative routes. Is is enabled
in the configuration of the usage guide and a bootstrap configuration is
provided.

**Tip: ** When your app already depends on Cldr use `Routex.Extension.Cldr` to
generate the alternative routes for you.

```diff
# already done in USAGE guide
use Routex.Backend,
extensions: [
  Routex.Extension.AttrGetters, # required
+ Routex.Extension.Alternatives,
],
+ alternatives: %{
+      "/" => %{
+        branches: %{
+          "/europe" => %{
+              branches: %{
+                "/nl" => %{},
+                "/fr" => %{}
+            }
+          },
+          "/gb" => %{}
+        }
+      }
+    }
```

You can confirm it works by running `mix phx.routes`. It now shows a lot more
routes as alternatives are generated for each route within the
`preprocess_using` block. For example the route to `/products/:id/show/edit` has
multiple alternatives.

```
GET     /products/:id/show/edit               ExampleWeb.ProductLive.Show :edit
GET     /europe/products/:id/show/edit        ExampleWeb.ProductLive.Show :edit
GET     /europe/fr/products/:id/show/edit     ExampleWeb.ProductLive.Show :edit
GET     /europe/nl/products/:id/show/edit     ExampleWeb.ProductLive.Show :edit
GET     /gb/products/:id/show/edit            ExampleWeb.ProductLive.Show :edit
```


## Step 2: Translate the alternative routes

As you can see the routes are still in the English language. To increate usability and
better Search Engine Optimization (SEO) we want routes in the users language.

The `Routex.Extension.Translation` makes routes translatable by splitting the route
into segments (e.g. `["products", "show", "edit"]`) and extracting these
segments to a `routes.po` file for translation.

> ##.PO files{:.info}
> You might recognize the `.po` extension from your Phoenix project; it's the
> extension used by Gettext. Gettext is a standard for i18n in different
> communities, meaning there is a great set of tooling for developers and
> translators. This also means your routes segments can be translated with the
> same tooling as used for all other translations in Phoenix!

Uncomment the extension and set the correct Gettext backend.

```diff
use Routex.Backend,
extensions: [
  Routex.Extension.AttrGetters, # required
  Routex.Extension.Alternatives,
- # Routex.Extension.Translations,
+ Routex.Extension.Translations,
],
  alternatives: %{...},
- # translations_backend: ExampleWeb.Gettext,
+ translations_backend: [MyApp]Web.Gettext,
```

As Routex need to know which translation to use for what route, we need to set
an attribute `:locale` or `:language` per alternative.

Luckily this is covered by `Extension.Alternatives` as it supports setting attributes
per branch using `:attrs`. Let's extend the alternatives configuration by
setting the `:locale` attribute.

_Simplified: A locale is formatted as [language]-[region]. "en-GB" is shorthand
 for [language: "en", region: "GB"] and "en-001" uses `region: "World"`._

```diff
 alternatives: %{
      "/" => %{
+        attrs: %{locale: "en-001"},
         branches: %{
           "/europe" => %{
+              attrs: %{locale: "en-150"},
               branches: %{
+                "/nl" => %{attrs: %{locale: "nl-NL"}},
+                "/fr" => %{attrs: %{locale: "fr-FR"}}
             }
           },
+          "/gb" => %{attrs: %{locale: "en-GB"}}
         }
       }
     }
```

If this is the first time you add translations in your project, you need to
generate the folder structure which Gettext can use to detect languages to
translate to. We need tree languages in this tutorial: 'en', 'nl' and 'fr'. As 'en' is
the default for routes we only need to create translations for 'nl' and 'fr'.

```
mix gettext.extract
mix gettext.merge priv/gettext --locale nl
mix gettext.merge priv/gettext --locale fr
```

You should see a message that Gettext has generated new translation files which
can be found in the `priv/gettext/nl` and `priv/gettext/fr` folders.

```
priv/
 gettext/
   nl/
     LC_MESSAGES/
       default.po # phoenix translations
       routes.po  # routex translations
    fr/
     LC_MESSAGES/
       default.po # phoenix translations
       routes.po  # routex translations
```

Now you can translate the segments by opening the `routes.po` file with your
favorite `.po` editor. Here are a few suggestions:

* `Lokalize`: runs on KDE desktop for Linux
* `Poedit`: Linux, MacOSX, and Windows
* `OmegaT`: Linux, MacOSX, and Windows
* `gted plugin for Eclipse`: (if you are already using Eclipse)
* `gtranslator`: Linux/Gnome
* `Virtaal`: Windows, Mac

Once you have translated the route segments, list all routes using `mix
phx.routes`. You will see some routes have been translated. We are getting
there!

```
GET     /products/:id/show/edit
GET     /europe/products/:id/show/edit
GET     /europe/fr/produit/:id/montrer/traiter
GET     /europe/nl/producten/:id/toon/bewerken
```

## Step 3: Dynamic links in your application

In the templates the path of the link to the products page is written as
`~p"/products"`. Without `Routex.Extension.VerifiedRoutes` every link to
the products page would bring you back to the non-locale route `/products`.
`Routex.Extension.VerifiedRoutes` makes Phoenix.VerifiedRoutes branch aware.

> **Note**
> In older Phoenix applications you might find something like
> `ExampleAppWeb.Router.Helpers.product_path(conn_or_endpoint, :show, "hello")`.
> These are Phoenix Router Helpers and those are deprecated in favor of the
> Verified Routes using `~p"/my_path"`. When you can't migrate, you can use
> `Routex.Extension.RouteHelpers` instead of `Routex.Extension.VerifiedRoutes`.

In the configuration provide in the usage guide, we chose to override the names
used by Phoenix in your application and rename the originals. This way you do
not need to modify all your templates. Convenient.

```diff
# already done in USAGE guide
use Routex.Backend,
  extensions: [
    Routex.Extension.AttrGetters, # required
    Routex.Extension.Alternatives,
    Routex.Extension.Translations,
  + Routex.Extension.VerifiedRoutes,
  ],
  alternatives: %{...},
  translations_backend: ExampleWeb.Gettext,
+ verified_sigil_routex: "~p",
+ verified_sigil_phoenix: "~o",
+ verified_url_routex: :url,
+ verified_path_routex: :path
```

You already made the change in `example_web.ex` to include the macro's from Routex
instead of the official ones.

```diff
  # already done in USAGE guide
  def routex_helpers do
    quote do
+      import Phoenix.VerifiedRoutes,
+        except: [sigil_p: 2, url: 1, url: 2, url: 3, path: 2, path: 3]

      import unquote(__MODULE__).Router.RoutexHelpers, only: :macros
      alias unquote(__MODULE__).Router.RoutexHelpers, as: Routes
    end
  end
```

When you start your app with `mix phx.server` you will notice an explanation is
printed about the usage of Routex Verified Routes. This informs other developers
of the overrides.

```
Due to the configuration in module `ExampleWeb.RoutexBackend` one or multiple
Routex variants use the default name of their native Phoenix equivalents. The native
macro's, sigils or functions have been renamed.

 Native              | Routex
 -----------------------------------------
 ~o                  | ~p
 url_phx             | url
 path_phx            | path

 Documentation: https://hexdocs.pm/routex/extensions/verified_routes.html
 ```


When you visit a 'localized' page such as `/europe/nl/producten` every link on
the page will keep you within the localized branch `/europe/nl/`. Keeping users
in a localized branch is great, but giving them an option to switch to another
locale would be even better.

Let's empower our visitors!

## Step 5: Set the locale other libraries such as Gettext, Fluent and Cldr

Enable `Routex.Extension.SimpleLocale` in the list of extensions. This extension
adds `language_display_name` and `region_display_name` to a routes attributes
during compilation (those are derived from the `locale` attribute). It also
provides Liveview lifecycle hooks and Plug to set the `language`, `region` and
`locale` attributes during runtime. Those are automatically enabled by Routex.

By default, this is the order of language detection:
`[:query, :session, :cookie, :accept_language, :path, :attrs]`

As our routes are translated it makes sense to also use the language of the
route for the content of the pages. We need to priotize `:attrs` over
auto-detection using `:accept_language`.

```
+ language_sources: [:query, :session, :cookie, :attrs, :accept_language]
```

`Routex.Extension.RuntimeCallbacks` completes it. It can call a list of
arbitrary functions using `{m, f, a}` notation. It's configured to call
`Gettext.put_locale(get_in(attrs, [:language]))`

```elixir
# already done in USAGE guide
# every argument formatted as a list starting with `:attrs` is converted to a call to get_in(attrs(), rest)
runtime_callbacks: [{Gettext, :put_locale, [[:attrs, :language]]}],
```

## Step 4: Show alternative pages to the user

The `Routex.Extension.AlternativeGetters` generates function at compile time to
dynamically fetch alternative routes for the current url without overhead.

```diff
use Routex.Backend,
extensions: [
  Routex.Extension.AttrGetters, # required
  Routex.Extension.PhoenixLiveviewHooks,
  Routex.Extension.Plugs,
  Routex.Extension.RuntimeCallbacks,
  Routex.Extension.Alternatives,
  Routex.Extension.Translations,
  Routex.Extension.VerifiedRoutes,
  Routex.Extension.AlternativeGetters,
],
  alternatives: %{...},
  translations_backend: ExampleWeb.Gettext,
  verified_sigil_routex: "~p",
  verified_sigil_phoenix: "~o",
  verified_url_routex: :url,
  verified_path_routex: :path
```

All created functions pattern match on a given URL and return the alternatives
with a `slug`, the `match?` attribute which is `true` if the route pattern matches
the provided path, and `attributes` of the route.

```
iex> ExampleWeb.Router.RoutexHelpers.alternatives("https://example.com/products?search=bar#top")
[
  %Routex.Extension.AlternativeGetters{
    slug: "/products?search=bar#top",
    attrs: %{
      name: "Worldwide",
      locale: "en-US",
      [...]
    },
    match?: true
  },
  %Routex.Extension.AlternativeGetters{
    slug: "/europe/products?search=bar#top",
    attrs: %{
      name: "Europe",
      locale: "en-150",
      [...]
    },
    match?: false
  },
  %Routex.Extension.AlternativeGetters{
    slug: "/europe/be/producten?search=bar#top",
    attrs: %{
      name: "Belgium",
      locale: "nl-BE",
       [...]
    },
    match?: false
  },
  [...]
```

As Routex automatically assigns the current url to `@url` and
`Routex.Extension.SimpleLocale` added some display names, we have all
ingredients instantly available in our templates! It becomes a matter of looping
over the results to generate links.

```heex
 <!-- alternatives/1 is located in ExampleWeb.Router.RoutexHelpers which is aliased as Routes -->
 <.link
   :for={alternative <- Routes.alternatives(@url)}
   class="button"
   rel="alternate"
   hreflang={alternative.attrs.language}
   navigate={alternative.slug}
 >
   <.button class={(alternative.match? && "bg-[#FD4F00]") || ""}>
     <%= alternative.attrs.region_display_name %>
   </.button>
 </.link>
```


## Conclusion
In this tutorial you have learned how to create localized routes for your
Phoenix application using multiple extensions and custom attributes
(such as `:locale`). We also used extension RuntimeCallbacks to call other packages a the runtime using
Routex attributes.

There are a few more extension you can add to the mix for extra flexibility and convenience, such as:

* **`Routex.Extension.Assigns`** - Use any attribute in your templates using `@`
  notation.
* **`Routex.Extension.Interpolation`** - Use any attribute to customize routes  
  (e.g. `/#{locale}/products/#{display_name}/:id/edit`)

Feel free to [open a topic at Elixir Forums](https://elixirforum.com/tag/routex)
when you need help with this tutorial. When you are certain you encounter a bug
please create an issue at GitHub.

Have a nice day!
