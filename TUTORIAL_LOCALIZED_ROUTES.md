# Localized Routes with Routex

A core feature of Routex is to enable Localized Routes in Phoenix. Optionally with
translated URLs, enhancing user engagement and content relevance.

In this tutorial we will explain how multiple extensions are combined to...
1. have a product page with regional URL's
2. (optional) use translated routes
2. using automatically localized verified routes
3. display links to other locales

All without changing a single route in your templates!


                        ⇒ /products/:id/edit                    @loc.locale = "en_US"
    /products/:id/edit  ⇒ /eu/nederland/producten/:id/bewerken  @loc.locale = "nl_NL"
                        ⇒ /eu/espana/producto/:id/editar        @loc.locale = "es_ES"
                        ⇒ /gb/products/:id/edit                 @loc.locale = "en_GB"


This tutorial assumes you have followed the [usage guide](USAGE.md) to setup
Routex.

If you encounter any issues with Routex or this tutorial, feel free to [open a topic at Elixir
Forums](https://elixirforum.com/tag/routex) or create an issue at GitHub.


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

The `Routex.Extension.Alternatives` generates alternative routes. Add it to the list of extensions
and provide a minimal configuration.

```diff
use Routex.Backend,
extensions: [
+ Routex.Extension.Alternatives,
],
+ alternatives: %{
+      "/" => %{
+        branches: %{
+          "/europe" => %{
+              branches: %{
+                "/nl" => %{},
+                "/be" => %{}
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
product_show_path           GET     /products/:id/show/edit               ExampleWeb.ProductLive.Show :edit
product_show_europe_path    GET     /europe/products/:id/show/edit        ExampleWeb.ProductLive.Show :edit
product_show_europe_be_path GET     /europe/be/products/:id/show/edit     ExampleWeb.ProductLive.Show :edit
product_show_europe_nl_path GET     /europe/nl/products/:id/show/edit     ExampleWeb.ProductLive.Show :edit
product_show_gb_path        GET     /gb/products/:id/show/edit            ExampleWeb.ProductLive.Show :edit
```

As you can see the routes are still in the English language; we need another extension to
translate them


## (optional) Step 2: Translate the alternative routes

The `Routex.Extension.Translation` makes routes translatable by splitting the route
into segments (e.g. `["products", "show", "edit"]`) and extracting these
segments to a `routes.po` file for translation. You might recognize the `.po`
extension from your Phoenix project; it's the extension used by Gettext. Gettext
is a standard for i18n in different communities, meaning there is a great set of
tooling for developers and translators. This also means your routes segments can be
translated with the same tooling as used for all other translations in Phoenix!

Add the extension and it's minimal configuration.

```diff
use Routex.Backend,
extensions: [
  Routex.Extension.Alternatives,
+ Routex.Extension.Translations,
],
  alternatives: %{...},
+ translations_backend: ExampleWeb.Gettext,
```

As Routex need to know which translation to use for what route, we need to set
an attribute `:locale` or `:language` per alternative.

Luckily this is covered by `Extension.Alternatives` as it supports setting the
`:attrs` key per branch. Let's extend the alternatives configuration with by
setting the `:locale` attribute. While we are add it, we also give the branches
a `:display_name` attribute.

```diff
 alternatives: %{
      "/" => %{
+        attrs: %{locale: "en-150", display_name: "Global"},
         branches: %{
           "/europe" => %{
+              attrs: %{locale: "en-150", display_name: "Europe"},
               branches: %{
+                "/nl" => %{attrs: %{locale: "nl_NL", display_name: "The Netherlands"}},
+                "/be" => %{attrs: %{locale: "nl_BE", display_name: "Belgium"}}
             }
           },
+          "/gb" => %{attrs: %{locale: "en-150", display_name: "Great Britain"}}
         }
       }
     }
```

If this is the first time you add translations in your project, you need to
generate the folder structure which Gettext can use to detect languages to
translate to. We need two languages in this tutorial: 'en' and 'nl'. As 'en' is
the default for routes we only need to create translations for 'nl'.

```
mix gettext.extract
mix gettext.merge priv/gettext --locale nl
```

You should see a message that Gettext has generated new translation files which
can be found in the `priv/gettext/nl` folder

```
priv/
 gettext/
   nl/
     LC_MESSAGES/
       default.po # phoenix translations
       routes.po  # routex translations
```

Now you can translate the segments by opening the `routes.po` file with your
favorite `.po` editor. Here are a few suggestions:

* `GNU Emacs (with po-mode)`: Linux, MacOSX, and Windows.
* `Lokalize`: runs on KDE desktop for Linux (replacement for KBabel; formerly known as KAider)
* `Poedit`: Linux, MacOSX, and Windows
* `OmegaT`: Linux, MacOSX, and Windows
* `Vim`: Linux, MacOSX, and Windows with PO ftplugin for easier editing of GNU gettext PO files.
* `gted plugin for Eclipse`: (if you are already using Eclipse)
* `gtranslator`: Linux/Gnome
* `Virtaal`: Windows, Mac (Beta version)

Once you have translated the route segments, list all routes using `mix
phx.routes`. You will see some routes have been translated. We are getting
there!

```
product_show_path            GET     /products/:id/show/edit
product_show_europe_path     GET     /europe/products/:id/show/edit
product_show_europe_be_path  GET     /europe/be/producten/:id/toon/bewerken
product_show_europe_nl_path  GET     /europe/nl/producten/:id/toon/bewerken
```

Now we have the routes it would be nice if users stay within their `locale`
while browsing pages.

## Step 3: Dynamic links in your application

When you start your app with `mix phx.server` and you visit a 'localized' page
such as `/europe/nl/producten`, you will notice that every link on the page will
bring you back to the non-locale route. In the code the path of the link is written
like `~p"/products"`. It would be nice if instead of always rendering a link to
`/products`, Phoenix would instead render a localized link. This is done by
`Routex.Extension.VerifiedRoutes`.

> **Note**
> In older Phoenix applications you might find something like
> `ExampleAppWeb.Router.Helpers.product_path(conn_or_endpoint, :show, "hello")`.
> These are Phoenix Router Helpers and those are deprecated in favor of the
> Verified Routes using `~p"/my_path"`. When you can't migrate, you can use
> `Routex.Extension.RouteHelpers` instead of `Routex.Extension.VerifiedRoutes`.

You might already have guessed it: we are gonna add the extension and some
configuration to the backend.

```diff
use Routex.Backend,
extensions: [
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

By default the extension uses non-standard macro names. As we want to have
dynamic routes throughout our application, we choose to override the names used
by Phoenix in your application and rename the originals. This way you do not
need to modify all your templates. Convenient.

To not have duplicated imports, add this to your routex_helpers in `example_web.ex`

```diff
  def routex_helpers do
    quote do
+      import Phoenix.VerifiedRoutes,
+        except: [sigil_p: 2, url: 1, url: 2, url: 3, path: 2, path: 3]

      import unquote(__MODULE__).Router.RoutexHelpers, only: :macros
      alias unquote(__MODULE__).Router.RoutexHelpers, as: Routes
    end
  end
```

Now when you start your app with `mix phx.server` you will notice an explanation
is printed about the usage of Routex Verified Routes. This informs other
developers of the 'take overs'.

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


When you visit a 'localized' page such as `/europe/nl/producten` you will notice
that every link on the page will keep you within the localized environment
`/europe/nl/`. Keeping users in a localized environment is great, but giving
them an option to switch to another locale would be even better.

Let's empower our visitors!

## Step 4: Show alternative pages to the user

The `Routex.Extension.AlternativeGetters` generates function at compile time to
dynamically fetch alternative routes for the current url without overhead. Let's
once again add the extension.

```diff
use Routex.Backend,
extensions: [
  Routex.Extension.Alternatives,
  Routex.Extension.Translations,
  Routex.Extension.VerifiedRoutes,
+ Routex.Extension.AlternativeGetters,
],
  alternatives: %{...},
  translations_backend: ExampleWeb.Gettext,
  verified_sigil_routex: "~p",
  verified_sigil_phoenix: "~o",
  verified_url_routex: :url,
  verified_path_routex: :path
```

All created functions pattern match on a given URL and return the alternatives
with a `slug`, the `match?` attribute which is true if the route pattern matches
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

As Routex automatically assigns the current url to `@url` we have all
ingredients instantly available in our templates! It becomes a matter of looping
over the results to generate links.

```heex
 <!-- alternatives/1 is located in ExampleWeb.Router.RoutexHelpers which is aliased as Routes -->
 <.link
   :for={alternative <- Routes.alternatives(@url)}
   class="button"
   rel="alternate"
   hreflang={alternative.attrs.locale}
   patch={alternative.slug}
 >
   <.button class={(alternative.match? && "bg-[#FD4F00]") || ""}>
     <%= alternative.attrs.display_name %>
   </.button>
 </.link>
```


## Conclusion
In this tutorial you have learned how to create localized routes for your
Phoenix application using multiple extensions and how to add custom attributes
(such as `:locale` and `:display_name`) to these routes. There are a few more
extension you can add to the mix for extra flexibility and convenience, such as:

* **Routex.Extension.Interpolation** - Use any attribute to customize routes
  (e.g. "/#{locale}/products/#{display_name}/:id/edit")
* **Routex.Extension.Assigns** - Use any attribute in your templates using `@`
  notation.
* **Routex.Extension.AttrGetters** - Lazy load attributes

If you encounter any issues with Routex or this tutorial, feel free to [open a topic at Elixir
Forums](https://elixirforum.com/tag/routex) or create an issue at GitHub.

Have a nice day!
