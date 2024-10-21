![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)


# Routex

Routex serves as a framework designed to extend the capabilities of Phoenix'
router. Leveraging a flexible extension system, it is able to transform routes,
generate alternative routes and generate helper functions based on routes
within you Phoenix Framework application. Positioned as middleware between route
definition and compilation by Phoenix, Routex ensures (close to) zero impact on
runtime performance.

## Top Features and Benefits

- **extension driven**: mix and match the features you need.
- **performant**: (close to) zero run time impact.
- **extensible**: write your own routing features with ease.
- **plug-and-play**: enable site wide features with a single config change.
- **easy setup**: Routex extensions provide drop-in alternatives with only a few lines of code.


## Documentation

[HexDocs](https://hexdocs.pm/routex) (stable) and [GitHub
Pages](https://bartotten.github.io/routex) (development).

[Summary of all official Routex extensions](#extensions)


## Requirements and Installation

See the [Usage Guide](USAGE.md) for the requirements and installation
instructions.


## Example

Localize your Phoenix website with multilingual URLs and custom template
assigns; enhancing user engagement and content relevance. This example combines
a few of the included extensions: `Alternatives`, `Translations`, `Assigns` and
`Verified Routes`.

                        ⇒ /products/:id/edit                      @loc.locale = "en_US"
    /products/:id/edit  ⇒ /eu/nederland/producten/:id/bewerken    @loc.locale = "nl_NL"
                        ⇒ /eu/espana/producto/:id/editar          @loc.locale = "es_ES"
                        ⇒ /gb/products/:id/edit                   @loc.locale = "en_GB"

- `Alternatives` to generate 4 route branches, with custom attributes per branch.
- `Translation` to localize the urls enhanding user engagement and content relevance.
- `Assigns` to access attributes of a route in LiveViews, components and
  controllers using `loc` as namespace (`@loc.locale`)
- `Verified Routes` to keep  `~p"/products/#{product}/edit"` in templates. At run-time the route is
  combined with the set `locale` to pick the localized alternative route.


## Routex vs CLDR Routes vs Phoenix Localized Routes

The capabilities and advancements within `Routex` surpass those of `Phoenix
Localized Routes`, offering a comprehensive array of features. As Phoenix
Localized Routes has stagnated in its development, developers are strongly
advised to transition to Routex for a more robust solution.

When considering `Routex` against `CLDR Routes`, it's akin to comparing Apple to
Linux. CLDR Routes maintains a fixed scope and enjoys a shared configuration
with other CLDR packages. Routex on the other hand boasts a dynamic scope
providing maximum freedom. Its primary advantages over CLDR Routes include its
expansive branch facilitated by its extension mechanism and the minimized
necessity for code modifications throughout a codebase.

### Comparison table

| Feature             | Routex     | CLDR Routes | PLR        |
|---------------------|------------|-------------|------------|
| Route encapsulation | Full  [^1] | Limited     | Limited    |
| Route manipulation  | Full  [^2] | Limited     | Limited    |
| Route interpolation | Full       | Limited     | No         |
| Alternative Routes  | Full       | CLDR        | Full       |
| Translation         | ☑          | ☑          |  ☑         |
| Route Helpers       | ☑          | ☑          |  ☑         |
| Verified Routes     | ☑          | ☑          |  ☐         |
| Drop-in replacement | ☑     [^3] | ☐          |  ☑         |
| Standalone          | ☑          | ☐          |  ☐         |
| Modular             | ☑          | ☐          |  ☐         |
| Extendable          | ☑          | ☐          |  ☐         |

[^1]: Routex' `preprocesss_using` is not bound to Phoenix (session) scopes
[^2]: [Crazy example](https://github.com/BartOtten/routex/blob/main/lib/routex/extension/cloak.ex)
[^3]: Routex *can* be configured to shim original Phoenix functionality (for
    example: `~p` and `url/2`) while CLDR Routes mandates code modifications
    (for example: `~p` -> `~q` and `url/2` -> `url_q/2`)


## Extensions

Routex relies on extensions to provide features. Each extension provides a
single feature and should minimize hard dependencies on other extensions.
Instead, Routex advises to make use of `Routex.Attrs` to share attributes;
allowing extensions to work together whithout being coupled.

The documentation of each extension lists any provided or required
`Routex.Attrs`.


### Alternatives

Create alternative routes based on `branches` configured in a Routex backend
module. Branches can be nested and each branch can provide it's own attributes to
be shared with other extensions.

[Alternatives Documentation](`Routex.Extension.Alternatives`)


### Translations

This extension extracts segments of a routes' path to a `routes.po` file for
translation. At compile-time it combines the translated segments to translate
routes. As a result, users can enter URLs using localized terms which can
enhance user engagement and content relevance.

[Translations Documentation](`Routex.Extension.Translations`)


### Multilingual Routes

The Alternatives extension can be combined with the Translations extension to
create multilingual routes. The Alternatives extension can provide the :locale
attribute used by the Translations extension.

    Original            Step 1: Alternatives                    Step 2: Translations

						⇒ /products/:id/edit                    ⇒ /products/:id/edit
	/products/:id/edit  ⇒ /eu/nederland/products/:id/edit       ⇒ /eu/nederland/producten/:id/bewerken
						⇒ /eu/espana/products/:id/edit		    ⇒ /eu/espana/producto/:id/editar
						⇒ /gb/products/:id/edit				⇒ /gb/products/:id/edit


### Alternative Getters

Creates a helper function `alternatives/1` to get a list of alternative slugs
and their routes attributes. As `Routex` sets the `@url` assign you can simply
get other routes to the current page with `alternatives(@url)`.

[Alternative Getters Documentation](`Routex.Extension.AlternativeGetters`)


### Verified Routes

Routex is fully compatible with Verified Routes.

This extension creates a sigil (default: `~l`) with the ability to branch based
on the current alternative branch of a user. It is able to verify routes even
when thy have been transformed by Routex extensions. Optionally this sigil can
be set to `~p` (Phoenix' default) as it is a drop-in replacement.

It also provides branching variants of `url/{2,3,4}` and `path/{2,3}`.

[Verified Routes Documentation](`Routex.Extension.VerifiedRoutes`)


### Route Helpers

Creates Phoenix Helpers that have the ability to branch based on the current
alternative branch of a user. Optionally these helpers can replace the original
Phoenix Route Helpers as they are drop-ins.

[Route Helpers Documentation](`Routex.Extension.RouteHelpers`)


### Interpolation

With this extension enabled, *any* attribute assigned to a route can be used
for route interpolation. Most effective with an extension which enables
alternative routes generation (such as extension `Alternatives`).

    /product/#{territory}/:id/#{language}  => /product/europe/:id/nl

[Interpolation Documentation](`Routex.Extension.Interpolation`)


### Assigns

With this extension you can add (a subset of) attributes set by other extensions
to Phoenix' assigns making them available in components and controllers with the
`@` assigns operator (optionally under a namespace)

    @namespace.area      =>  :eu_nl
	@namespace.contact   =>  "contact@example.com"

[Assigns Documentation](`Routex.Extension.Assigns`)


### Attribute Getters

Creates a helper function `attrs/1` to get all `Routex.Attrs` of a route. As
`Routex` sets the `@url` assign you can simply get all attributes for the
current page with `attrs(@url)`.

This way the `assigns` can be a subset of the full list of attributes but the
full list can be lazy loaded when needed.

[Attribute Getters Documentation](`Routex.Extension.AttrGetters`)


### Cloak (only for experiments)

Transforms routes to be unrecognizable. This extension is a show case and may
change at any given moment to generate other routes without prior notice.

      /products/  ⇒ /01
      /products/:id/edit  ⇒ /:id/02      ⇒ in browser: /1/02, /2/02/ etc...
      /products/:id/show/edit  ⇒ /:id/03   ⇒ in browser: /1/03, /2/03/ etc...


[Attribute Getters Documentation](`Routex.Extension.Cloak`)

