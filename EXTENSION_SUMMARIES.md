# Routex Extensions

Routex relies on extensions to provide features. Each extension provides a
single feature and should minimize hard dependencies on other extensions.
Instead, Routex advises to make use of `Routex.Attrs` to share attributes;
allowing extensions to work together without being coupled.

The documentation of each extension lists any provided or required
`Routex.Attrs`.


## Alternatives

Create alternative routes based on `branches` configured in a Routex backend
module. Branches can be nested and each branch can provide it's own attributes to
be shared with other extensions.

[Alternatives Documentation](https://hexdocs.pm/routex/Routex.Extension.Alternatives.html)


## Translations

This extension extracts segments of a routes' path to a `routes.po` file for
translation. At compile-time it combines the translated segments to translate
routes. As a result, users can enter URLs using localized terms which can
enhance user engagement and content relevance.

[Translations Documentation](https://hexdocs.pm/routex/Routex.Extension.Translations.html)


### Multilingual Routes

The Alternatives extension can be combined with the Translations extension to
create multilingual routes. The Alternatives extension can provide the :locale
attribute used by the Translations extension.

	Original            Step 1: Alternatives               Step 2: Translations
						⇒ /products/:id/edit               ⇒ /products/:id/edit
	/products/:id/edit  ⇒ /eu/nederland/products/:id/edit  ⇒ /eu/nederland/producten/:id/bewerken
						⇒ /eu/espana/products/:id/edit	   ⇒ /eu/espana/producto/:id/editar
						⇒ /gb/products/:id/edit            ⇒ /gb/products/:id/edit


## Alternative Getters

Creates a helper function `alternatives/1` to get a list of alternative slugs
and their route attributes.  The current route is also included and has attribute
`current?: true`. As `Routex` sets the `@url` assign you can simply
get all routes to the current page with `alternatives(@url)`, use an attribute in the
route as button text and highlight the current active route button.

[Alternative Getters Documentation](https://hexdocs.pm/routex/Routex.Extension.AlternativeGetters.html)


## Verified Routes

Routex is fully compatible with Verified Routes.

This extension creates a sigil (default: `~l`) with the ability to branch based
on the current alternative branch of a user. It is able to verify routes even
when thy have been transformed by Routex extensions. Optionally this sigil can
be set to `~p` (Phoenix' default) as it is a drop-in replacement.

It also provides branching variants of `url/{2,3,4}` and `path/{2,3}`.

[Verified Routes Documentation](https://hexdocs.pm/routex/Routex.Extension.VerifiedRoutes.html)


## Route Helpers

Creates Phoenix Helpers that have the ability to branch based on the current
alternative branch of a user. Optionally these helpers can replace the original
Phoenix Route Helpers as they are drop-ins.

[Route Helpers Documentation](https://hexdocs.pm/routex/Routex.Extension.RouteHelpers.html)


## Interpolation

With this extension enabled, *any* attribute assigned to a route can be used
for route interpolation. Most effective with an extension which enables
alternative routes generation (such as extension `Alternatives`).

    /product/#{territory}/:id/#{language}  => /product/europe/:id/nl

[Interpolation Documentation](https://hexdocs.pm/routex/Routex.Extension.Interpolation.html)


## Assigns

With this extension you can add (a subset of) attributes set by other extensions
to Phoenix' assigns making them available in components and controllers with the
`@` assigns operator (optionally under a namespace)

    @namespace.area      =>  :eu_nl
	@namespace.contact   =>  "contact@example.com"

[Assigns Documentation](https://hexdocs.pm/routex/Routex.Extension.Assigns.html)


## Attribute Getters

Creates a helper function `attrs/1` to get all `Routex.Attrs` of a route. As
`Routex` sets the `@url` assign you can simply get all attributes for the
current page with `attrs(@url)`.

This way the `assigns` can be a subset of the full list of attributes but the
full list can be lazy loaded when needed.

[Attribute Getters Documentation](https://hexdocs.pm/routex/Routex.Extension.AttrGetters.html)


## Cldr Adapter
Adapter for projects using :ex_cldr.

[Cldr Adapter Documentation](https://hexdocs.pm/routex/Routex.Extension.Cldr.html)


## Cloak (show case)

Transforms routes to be unrecognizable. This extension is a show case and may
change at any given moment to generate other routes without prior notice.

In this example it numbers all routes starting at 01 and increments the counter
for each route. It also shifts the parameter to the left; causing a chaotic
route structure. Do note: this still works with the Verified Routes extension
while using the standard route (e.g. `<.link navigate={~p"/products">`) in
templates.


      Original                 Rewritten     Result (product_id: 88, 89, 90)
      /products                ⇒     /01     ⇒    /01
      /products/:id/edit       ⇒ /:id/02     ⇒ /88/02, /89/02, /90/02 etc...
      /products/:id/show/edit  ⇒ /:id/03     ⇒ /88/03, /89/03, /90/03 etc...


[Cloak Documentation](https://hexdocs.pm/routex/Routex.Extension.Cloak.html)
