# `Routex.Extension.Translations`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/translations.ex#L2)

Enables users to enter URLs using localized terms which can enhance user engagement
and content relevance.

Extracts segments of a routes' path to a translations domain file (default: `routes.po`)
for translation. At compile-time it combines the translated segments to transform routes.

This extension expects either a `:language` attribute or a `:locale` attribute. When only
`:locale` is provided it will try to extract the language from the locale tag. This algorithm
covers Alpha-2 and Alpha-3 codes (see:
[ISO](https://datatracker.ietf.org/doc/html/rfc5646#section-2.2.1))

This extension requires Gettext >= 0.26.

> #### In combination with... {: .neutral}
> How to combine this extension for localization is written in de [Localization Guide](guides/LOCALIZE_PHOENIX.md)

## Configuration
```diff
defmodule ExampleWeb.RoutexBackend do
use Routex.Backend,
extensions: [
  Routex.Extension.AttrGetters, # required
+ Routex.Extension.Translations
]
+ translations_backend: MyApp.Gettext,
+ translations_domain: "routes",
```

## Pseudo result
    # when translated to Spanish in the .po file
    # - products: producto
    # - edit: editar

    /products/:id/edit  ⇒ /producto/:id/editar

## `Routex.Attrs`
**Requires**
- language || locale

**Sets**
- none

## Use case(s)
This extension can be combined with `Routex.Extension.Alternatives` to create
multilingual routes.

Use Alternatives to create new branches and provide a `:language` or `:locale` per branch and
Translations to translate the alternative routes.

                        ⇒ /products/:id/edit                  language: "en"
    /products/:id/edit  ⇒ /nederland/producten/:id/bewerken   language: "nl"
                        ⇒ /espana/producto/:id/editar         language: "es"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
