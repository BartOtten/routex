![Coveralls](https://img.shields.io/coveralls/github/BartOtten/routex)
[![Build Status](https://github.com/BartOtten/routex/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/BartOtten/routex/actions/workflows/elixir.yml)
[![Last Updated](https://img.shields.io/github/last-commit/BartOtten/routex.svg)](https://github.com/BartOtten/routex/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/routex)](https://hex.pm/packages/routex)
![Hex.pm](https://img.shields.io/hexpm/l/routex)


# Routex
Routex is a framework to extend the functionality of Phoenix Frameworks'
router. Using a pluggable extension system it can transform routes, create
alternative routes and generate helper functions based on routes in your Phoenix
Framework app. It acts as middleware between route definition and route
compilation by Phoenix; in order to have minimal impact on run-time performance.

It ships with a small set of extensions and provides helper functions for
writing your own custom Phoenix router features.

## Top Features and Benefits
- none to minimal run-time performance penalty (depending on extensions).
- adding router features is plug-and-play.
- include only features you need in your product; less code is less bugs.
- write powerful extensions without the plumbing.

## Example
Localize your Phoenix website with multilingual URLs and custom template
assigns; enhancing user engagement and content relevance. This example combines
a few extensions: Alternatives, Translations, Assigns and Verified Routes.

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
- Verified Routes allows you to use use `~p"/products/#{product}/edit"` in your
  code. At run-time the route is combined with the set `locale` to pick the
  localized alternative route.

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
