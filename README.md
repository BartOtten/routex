![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)


# Routex
Routex serves as a framework designed to extend the capabilities of Phoenix'
router. Leveraging a flexible extension system, it is able to transform routes,
generate alternative routes, and generate helper functions based on routes
within you Phoenix Framework application. Positioned as middleware between route
definition and compilation by Phoenix, Routex ensures (close to) zero impact on
runtime performance.

It ships with a concise selection of extensions and utility functions enabling
you to craft custom features for your Phoenix router when the need arises.

## Top Features and Benefits
- (close to) zero runtime performance impact; depending on enabled extensions.
- adding router features is plug-and-play.
- write powerful extensions without the plumbing.
- cherry pick what you need; less code == less potential bugs.


## Example
Localize your Phoenix website with multilingual URLs and custom template
assigns; enhancing user engagement and content relevance. This example combines
a few of the included extensions: Alternatives, Translations, Assigns and
Verified Routes.

                        ⇒ /products/:id/edit                      @loc.locale = "en_US"
    /products/:id/edit  ⇒ /eu/nederland/producten/:id/bewerken    @loc.locale = "nl_NL"
                        ⇒ /eu/espana/producto/:id/editar          @loc.locale = "es_ES"
                        ⇒ /gb/products/:id/edit                   @loc.locale = "en_GB"

- Alternatives: the URL format is [customizable](#alternatives) (no mandatory
  _website.com/[locale]/page_)
- Translation: URLs [match the language of content](#multilingual-routes);
  enhancing user engagement and content relevance.
- Assigns: the value of `locale` is specified per scope by the configuration of
  the Alternatives extension.  The value is made available in components and
  controllers in namespace `loc` as `@loc.locale`
- Branching Verified Routes allows you to use use
  `~p"/products/#{product}/edit"` in your code. At run-time the route is
  combined with the set `locale` to pick the localized alternative route.

## Documentation

[HexDocs](https://hexdocs.pm/routex) (stable) and [GitHub
Pages](https://bartotten.github.io/routex) (development).

## Requirements and Installation

See the [Usage Guide](USAGE.md) for the requirements and installation
instructions.

## Extensions

Routex relies on extensions to provide features. Each extension provides a
single feature and should minimize hard dependencies on other extensions.
Instead, Routex advises to make use of `Routex.Attrs` to share attributes;
allowing extensions to work together whithout being coupled.

The documentation of each extension lists any provided or required
`Routex.Attrs`.

### Alternatives

Create alternative routes based on `scopes` configured in a Routex backend
module. Scopes can be nested and each scope can provide it's values to be shared
with other extensions.

[Alternatives Documentation](`Routex.Extension.Alternatives`)

### Interpolation

With this extension enabled, *any* attribute assigned to a route can be used 
for route interpolation. This allows for routes such as `/product/#{territory}/:id/#{language}`.

[Interpolation Documentation](`Routex.Extension.Interpolation`)

### Translations

This extension extracts segments of a routes' path to a `routes.po` file for
translation. At compile-time it combines the translated segments to translate
routes. As a result, users can enter URLs using localized terms which can
enhance user engagement and content relevance.

[Translations Documentation](`Routex.Extension.Translations`)

### Multilingual Routes

The Alternatives extension can be combined with the Translations extension to
create multilingual routes. The Alternatives extension provides the :locale
attribute used by the Translations extension.

### Verified Routes

This extension creates a sigil (default: `~l`) with the ability to branch based
on the current alternative scope of a user. It is able to verify routes even
when thy have been transformed by Routex extensions. Optionally this sigil can
be set to `~p` (Phoenix' default) as it is a drop-in replacement.

It also provides branching variants of `url/{2,3,4}` and `path/{2,3}`.

[Verified Routes Documentation](`Routex.Extension.VerifiedRoutes`)

### Route Helpers

Creates Phoenix Helpers that have the ability to branch based on the current
alternative scope of a user. Optionally these helpers can replace the original
Phoenix Route Helpers as they are drop-ins.

[Route Helpers Documentation](`Routex.Extension.RouteHelpers`)

### Assigns

With this extension you can add (a subset of) attributes set by other extensions
to Phoenix' assigns making them available in components and controllers with the
`@` assigns operator (optionally under a namespace)

    @namespace.area   =>  :eu_nl

[Assigns Documentation](`Routex.Extension.Assigns`)

### Alternative Getters

Creates a helper function `alternatives/1` to get a list of alternative slugs
and their routes attributes. As `Routex` sets the `@url` assign you can simply
get other routes to the current page with `alternatives(@url)`.

[Alternative Getters Documentation](`Routex.Extension.AlternativeGetters`)

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

      /products/  ⇒ /c/1
      /products/:id/edit  ⇒ /c/:id/2      ⇒ in browser: /c/1/2, /c/2/2/ etc...
      /products/:id/show/edit  ⇒ /:id/3   ⇒ in browser: /c/1/3, /c/2/3/ etc...


[Attribute Getters Documentation](`Routex.Extension.Cloak`)

## Routex vs CLDR Routes vs Phoenix Localized Routes

The capabilities and advancements within `Routex` surpass those of `Phoenix
Localized Routes`, offering a comprehensive array of features. As Phoenix
Localized Routes has stagnated in its development, developers are strongly
advised to transition to Routex for a more robust solution.

When considering `Routex` against `CLDR Routes`, it's akin to comparing Apple to
Linux. CLDR Routes maintains a fixed scope and enjoys a shared configuration
with other CLDR packages. Routex on the other hand boasts a dynamic scope
providing maximum freedom. Its primary advantages over CLDR Routes include its
expansive scope facilitated by its extension mechanism and the minimized
necessity for code modifications throughout a codebase.

### History

Embarking into 2022, the introduction of `Phoenix Localized Routes` brought an
innovative approach to route generation within the Phoenix ecosystem. This
library reimagined website route generation and introduced features such as
alternative route creation, the ability to translate URL segments using Gettext,
and easy route based template assignments.

The unveiling of Phoenix Localized Routes (PLR) captured the attention of the
main author behind CLDR. Recognizing its potential, he discerned that the lack
of modularity in PLR did not align with the requirements of CLDR. Consequently,
CLDR forked PLR, birthing `CLDR-routes`, tailored precisely to meet their unique
objectives. Initially, there was a spirit of collaboration between the two
endeavors, with shared code fostering mutual progress. However, over time, the
natural evolution of each project led to increasing disparities, hindering
further cooperation.

The debut of Phoenix 1.7, featuring verified routes, underscored the challenges
confronted by maintainers of PLR and CLDR-routes alike. The heavy reliance on
complex macros posed significant hurdles in adapting to this new
paradigm. Moreover, the growing divide between their codebases made the exchange
of solutions impractical.

In response to these obstacles, the creator of PLR took the initiative to
develop `Routex`. Inspired by the simplicity and versatility of Plug, Routex
embraces extensions, offering ease of maintenance and seamless integration into
diverse projects. Its modular design empowers developers to extend functionality
effortlessly, paving the way for the streamlined development of tailored
solutions.

### Comparison table

| Feature             | Routex     | PLR        | CLDR Routes |
|---------------------|------------|------------|-------------|
| Scope detection     | URL   [^1] | Session    | Session     |
| Route encapsulation | Free  [^2] | Restricted | Restricted  |
| Route manipulation  | Full  [^3] | Limited    | Limited     |
| Route interpolation | Free       | -          | Limited     |
| Alternative Routes  | Free       | Free       | CLDR        |
| Translation         | X          | X          | X           |
| Verified Routes     | X          | X          | X           |
| Route Helpers       | X          | X          | X           |
| Drop-in replacement | X     [^4] | X          | -           |
| Single-dep Phoenix  | X          | X          | -           |
| Modular             | X          |            | -           |
| Extendable          | X          |            | -           |

[^1]: Routex uses pattern matching to match the current URL to a scope
[^2]: Routex' `preprocesss_using` can encapsulate any code / is not bound within
    (session) scopes
[^3]: [Crazy example](https://github.com/BartOtten/routex/blob/main/lib/routex/extension/cloak.ex)
[^4]: Routex *can* be configured to shim original Phoenix functionality (for
    example: `~p` and `url/2`) while CLDR Routes mandates code modifications
    (for example: `~p` -> `~q` and `url/2` -> `url_q/2`)

