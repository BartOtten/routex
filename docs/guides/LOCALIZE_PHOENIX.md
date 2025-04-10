This tutorial explains how to use **Routex** to localize your **Phoenix**
application including multilingual, SEO-friendly URLs. In addition to showing
how to configure Routex, you’ll learn:

- **Why localized routes matter:** Enhance user experience, improve SEO, and support regional content.
- **How Routex works:** How the battery included framework supports locatization.
- **Step-by-step setup:** Configure your backend, set up translations, and add a language switcher.

## What You’ll Build

By the end of this tutorial, you will have:
- A set of locale-specific URLs for your product pages.
- Translated route segments based on your Gettext files.
- A language switcher component that keeps users within their localized scope.
- Guidance on further customization and troubleshooting.

For example, your routes may look like:

```
                       ⇒ /products/:id/edit                    @loc.locale = "en_US"
   /products/:id/edit  ⇒ /eu/nederland/producten/:id/bewerken  @loc.locale = "nl_NL"
                       ⇒ /eu/france/produit/:id/editar         @loc.locale = "fr_FR"
                       ⇒ /gb/products/:id/edit                 @loc.locale = "en_GB"
```

## Prerequisites

- A working Phoenix project with Routex installed. (See [Routex Usage
  Guide](/USAGE.md) for installation instructions.)
- Phoenix version ≥ 1.6 and Elixir version ≥ 1.11.

## Terminology
Slightly simplified for your convenience.

- `locale`: Formatted as `language`-`region`. "en-GB" is
  shorthand for language "en" and region "GB".
- `IANA`: The Internet Assigned Numbers Authority provides an official list
  of region- and language-identifier including display names
- `attribute`: custom value assigned to a route
- `assign`: value accesible using `@key` in templates
- `Accept-Language`: The HTTP Accept-Language request header indicates the
   natural language and locale that the _software client_ prefers.

---

## Step 1: Configuring the Routex Backend

Next, create (or update) your Routex backend module. This configuration
determines which extensions to use, how to generate alternative routes, and how
to integrate translations via Gettext.

An explanation of the configuration is at the bottom of this guide.

```elixir
defmodule ExampleWeb.RoutexBackend do
  @moduledoc """
  Configures Routex to enable localized and translated routes.
  """

  use Routex.Backend,
    extensions: [
      Routex.Extension.AttrGetters,         # Base attribute handling
      Routex.Extension.LiveViewHooks,       # Inlines LiveView lifecycle callbacks of other extensions
      Routex.Extension.Plugs,               # Inlines plug callbacks of other extensions
      Routex.Extension.Alternatives,        # Generates locale alternatives
      Routex.Extension.AlternativeGetters,  # Creates a helper function to get the alternatives for a route
      Routex.Extension.Translations,        # Enables route segment translations
      Routex.Extension.VerifiedRoutes,      # Make Phoenix VerifiedRoutes branch aware
      Routex.Extension.SimpleLocale,        # Detects locale from various sources, adds :language and :region attributes to routes.
      Routex.Extension.RuntimeCallbacks,    # Supports callbacks during runtime (e.g Gettext.put_locale/{1.2})
    ],

    # Integration with Gettext for route segment translation.
    translations_backend: ExampleWeb.Gettext,

    # Override Phoenix VerifiedRoutes sigils with Routex variants.
    verified_sigil_routex: "~p",
    verified_sigil_phoenix: "~o",
    verified_url_routex: :url,
    verified_path_routex: :path,

    # Locales to generate routes for: English (Global), Dutch, French, English (Great Brittain) and English (European)
    locales: [{"en-001", %{region_display_name: "Worldwide"}}, "nl-NL", "fr-FR", "en-GB", "en-150"],
    default_locale: "en-100",

    # Language detection with custom source priority
    language_sources: [:query, :session, :cookie, :attrs, :accept_language],

    # Runtime callbacks to set Gettext locale from route attribute :language.
    runtime_callbacks: [{Gettext, :put_locale, [[:attrs, :language]]}]
end
```


---

## Step 2: Translate Route Segments

Generate the translation files for your routes:

```bash
mix gettext.extract
mix gettext.merge priv/gettext --locale nl
mix gettext.merge priv/gettext --locale fr
```

This creates the following structure:

```text
priv/
 gettext/
   nl/
     LC_MESSAGES/
       default.po  # phoenix translations
       routes.po   # routex translations
    fr/
     LC_MESSAGES/
       default.po  # phoenix translations
       routes.po   # routex translations
```

Translate your route segments using any `.po` file editor (Poedit, OmegaT, etc.).

---

## Step 3: Adding a Language Switcher Component

To improve user experience, add a component that lets users switch locales
seamlessly. Below is an example using a LiveView component with explicit styling
and accessibility features:

```heex
<.link
  :for={alternative <- Routes.alternatives(@url)}
  class="button"
  rel="alternate"
  hreflang={alternative.attrs.language}
  navigate={alternative.slug}>
  <.button class={if(alternative.match?, do: "bg-[#FD4F00]", else: "")}>
    <%= alternative.attrs.language_display_name %>
  </.button>
</.link>
```

### Component Highlights:
- **Looping over Alternatives:** Fetches all localized route variants for the current URL.
- **User Friendly Language Names:** Uses the `:language_display_name` as set by SimpleLocale.
- **Dynamic Styling:** Highlights the current language (using a conditional CSS class).
- **Accessible Markup:** Uses proper `rel` and `hreflang` attributes.

> **Next Steps:** Customize further using Tailwind CSS or your preferred
> framework and ensure it meets accessibility standards.

---

## Troubleshooting & Testing

### Common Pitfalls:
- **Missing Translation:** Ensure your PO files are updated and merged after any change.
- **Route Mismatch:** Run `mix phx.routes` to verify that all localized routes are generated.
- **Cookie/Session Issues:** Double-check your browser settings if locale detection does not work as expected.

---

## Additional Features & Customization

- **Extending Functionality:** If you need more complex transformations,
  consider writing your own Routex extension. The [Extension Development
  Guide](/docs/EXTENSION_DEVELOPMENT.md) offers detailed instructions.
- **Combining with Other Extensions:** Routex extensions are designed to work
  seamless together. Other extensions can be found in the [List of Routex
  Extensions](/docs/EXTENSIONS.md)
- **Enhance Usability:** Read our guide [Localization vs. Translation: Why Your
  Website Should Keep Them Separate](/docs/guides/LOCALIZATION_VS_TRANSLATION.md)

---

## Conclusion

This tutorial has guided you through localizing your Phoenix routes using Routex by:
- Explaining the benefits of localized routes.
- Providing a detailed configuration example with clear commentary.
- Demonstrating how to extract translations and build a language switcher.
- Offering troubleshooting and testing recommendations.

By following these steps, you now have a powerful and flexible routing system
that can adapt to any locale requirement without modifying your templates. For
further enhancements, check the official Routex documentation and join the
discussion on the [Elixir Forum](https://elixirforum.com/tag/routex).

Happy coding and enjoy creating a multilingual Phoenix application!


---

## The Configuration Explained
**AttrGetters, LiveViewHooks, Plugs**:
  - Extensions supporting other extensions.

**Alternatives Structure**:
  - Creates a hierarchical URL structure
  - Supports regional variations (e.g., European vs British English)
  - Associates locales with URL paths
  - Supports `[language|region]_display_name` overrides

**SimpleLocale with custom language sources**:
  - Expands route attribute `:locale` into route attributes `:locale, :region, :language, :region_display_name, :language_display_name`
  - Handles locale detection using a variery of sources including `Accept-Language`
  - Sets attributes `:locale`, `:region` and `:language` at runtime
  - Comes with an reduced IANA registry to validate locale-, region- and language and to convert these to display names
  - Custom detection source priority to favor the routes' language over the `Accept-Language` browser language.

**Translation Setup**:
  - Enables path segment translation
  - Uses the default translation lib use by Phoenix: Gettext.
  - Consistent segment localization

**Verified Routess**:
  - Preserves existing Phoenix path sigils (e.g. `~p"/my/path"`)
  - Adds locale awareness to routes
  - Maintains backward compatibility

 **AlternativeGetters**:
  - Fetch alternative locale routes using `alternatives(@url)`
  - Use to generate buttons to switch language

**RuntimeCallbacks**:
 - Configured to call `Gettext.put_locale`
 - Uses the runtime detected attribute `:language` which is set by SimpleLocale.
