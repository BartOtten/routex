# Routex Extensions

Routex includes a variety of extensions to cover the most common use cases in
Phoenix applications. Each extension provides a single feature and has no hard
dependencies on other extensions. Instead, extensions make use of Routex.Attrs
to share attributes; allowing extensions to work together without being coupled.

**Benefits**:
- **Modularity**: Each feature is encapsulated in its own extension, making
  it easier to manage and maintain.
- **Flexibility**: Extensions can be enabled or disabled as needed, allowing
  for a customizable and adaptable routing system.
- **Interoperability**: By using `Routex.Attrs` to share attributes, extensions
  can work together seamlessly without being tightly coupled, promoting a
  decoupled and scalable architecture.
- **Customizability**: If you have a rare requirement, you can adapt an existing
  extension or provide your own, without need for a fork or upstream support.

## Index

- [Alternatives](#alternatives): Create (nested) alternative routes.
- [Alternative Getters](#alternative-getters): Get alternatives for the current route.
- [Verified Routes](#verified-routes): Branch aware variant of Phoenix.VerifiedRoutes.
- [Assigns](#assigns): Use route attributes as assigns in templates.
- [Interpolation](#interpolation): Use attributes in route definitions.
- [Translations](#translations): Translate route segments / full localized URLs.
- [Attribute Getters](#attribute-getters): Retrieve `Routex.Attrs` for a route.
- [Cldr Adapter](#cldr-adapter): Use an existing `:ex_cldr`configuration.
- [Plugs](#plugs): Integrate plugs provided by extensions.
- [LiveView Hooks](#liveview-hooks): Attach LiveView Lifecycle hooks provided by extensions.
- [Route Helpers](#route-helpers): Create branch aware Phoenix Helpers.
- [Cloak](#cloak-showcase): Showcase to demonsrate extreme route transformations.

## Alternatives

**Feature**: Create alternative routes based on `branches` configured in a
Routex backend module. Branches can be nested, and each branch can provide its
own attributes to share with other extensions.

**Benefits**: Enables the definition of alternative routing paths and
their attributes in a single place.

**Example**: You can configure different branches for different locales or
versions of your application, providing users with the appropriate routes
based on their context.

[Alternatives Documentation](https://hexdocs.pm/routex/Routex.Extension.Alternatives.html)


## Alternative Getters

**Feature**: Creates a helper function `alternatives/1` to get a list of
alternative slugs and their route attributes. Includes the current route with
`match?: true` attribute.

**Benefits**: Simplifies the retrieval and use of alternative routes for the
current page.

**Example**: Easily display navigation buttons for alternative routes with
highlighting of the current active route.

```heex
<.link
   :for={alternative <- alternatives(@url)}
   navigate={alternative.slug}
 >
   <.button class={alternative.match? && "active" || "inactive"}>
     <%= alternative.attrs.display_name %>
   </.button>
 </.link>
 ```

[Alternative Getters Documentation](https://hexdocs.pm/routex/Routex.Extension.AlternativeGetters.html)

## Verified Routes

**Feature**: Creates a sigil (default: `~l`) that renders a link based on the
current branch of a user and verifies routes even when transformed by Routex
extensions. Can be set to `~p` to act as a drop-in replacement for the official
Phoenix sigils.

Also provides branch-aware variants of `url/{2,3,4}` and `path/{2,3}`.

**Benefits**: Ensures route integrity and security while supporting dynamic
route transformations.

**Example**: Use the `~p` sigil to generate URLs that adapt to the user's
current context or locale, ensuring they are always valid.

```elixir
# given Routex behavior is configured as drop-in replacement using ~p
# giving original ~p is reassigned to ~o
# given another extension has generated branches / alternative routes

~o"/products/#{product}"  ⇒  Phoenix.sigil_p("/products/#{products}")
~p"/products/#{product}"  ⇒
        case current_branch do
          nil     ⇒  Phoenix.sigil_p("/products/#{product}")
          "fr"    ⇒  Phoenix.sigil_p("/produits/#{product}")
          "es"    ⇒  Phoenix.sigil_p("/productos/#{product}")
        end
```

[Verified Routes Documentation](https://hexdocs.pm/routex/Routex.Extension.VerifiedRoutes.html)

## Assigns

**Feature**: Adds attributes set by other extensions to Phoenix assigns,
making them available in components and controllers.

**Benefits**: Provides easy access to route-specific attributes within the
application's components and controllers.

**Example**: Access route attributes like `@namespace.area` or
`@namespace.contact` directly in your templates.

```elixir
     @namespace.area      =>  :eu_nl
     @namespace.contact   =>  "contact@example.com"
```

[Assigns Documentation](https://hexdocs.pm/routex/Routex.Extension.Assigns.html)

## Interpolation

**Feature**: Allows -any- attribute assigned to a route to be used at -any-
place for route interpolation, especially effective with extensions like
`Alternatives`.

**Benefits**: Provides dynamic and customizable URL patterns based on various
attributes.

**Example**: Generate URLs like `/europe/products/nl/:id` where `territory` and
`language` are dynamically interpolated.

```elixir
    /#{territory/products/#{language}/:id  => /europe/products/nl/:id
```

[Interpolation Documentation](https://hexdocs.pm/routex/Routex.Extension.Interpolation.html)

## Translations

**Feature**: Extracts segments of a route's path to a `routes.po` file for
translation. At compile-time, it combines the translated segments to translate
routes, allowing users to enter URLs using localized terms.

**Benefits**: Enhances user engagement and content relevance by supporting
localized URLs.

**Example**: Users can visit your website using URLs in their own language,
such as `/productos` instead of `/products` for Spanish-speaking users.

[Translations Documentation](https://hexdocs.pm/routex/Routex.Extension.Translations.html)

## Attribute Getters

**Feature**: Creates a helper function `attrs/1` to get all `Routex.Attrs` of a
route.

**Benefits**: Allows conditional access to route attributes without affecting
performance.

**Example**: Retrieve all attributes for the current page with `attrs(@url)`.

[Attribute Getters Documentation](https://hexdocs.pm/routex/Routex.Extension.AttrGetters.html)

## Cldr Adapter

**Feature**: Provides integration for projects using `:ex_cldr`.

**Benefits**: Seamlessly integrates Routex with `:ex_cldr`.

**Example**: Utilize CLDR's localization features within your routing logic.

[Cldr Adapter Documentation](https://hexdocs.pm/routex/Routex.Extension.Cldr.html)

## Plugs

**Feature**: Detects and registers supported plug callbacks from other
extensions, encapsulating them in a single plug chain.

**Benefits**: Integrates extension plugs seamlessly, ensuring they are invoked
in order during the plug pipeline.

**Example**: Provides a unified plug that incorporates functionality from
multiple extensions, simplifying plug management.

## LiveView Hooks

**Feature**: Attaches LiveView hooks provided by Routex extensions, injecting
them into LiveView's lifecycle stages.

**Benefits**: Enables extensions to provide hooks for LiveView components,
enhancing their functionality and integration.

**Example**: Automatically invoke extension hooks during LiveView lifecycle
events like `handle_params`, `handle_event`, and `handle_info`.

## Route Helpers

**Feature**: Creates branch aware Phoenix Helpers. Can replace the original
Phoenix Route Helpers as drop-ins.

**Benefits**: Simplifies route handling and branching within Phoenix
applications.

**Example**: Use these helpers to generate URLs that adapt to the user's current
context or locale.

[Route Helpers Documentation](https://hexdocs.pm/routex/Routex.Extension.RouteHelpers.html)

## Cloak (showcase)

**Feature**: Transforms routes to be unrecognizable, demonstrating the
flexibility of Routex.

**Benefits**: Offers a way to obscure URL patterns for added security or
experimentation.

**Example**: Converts `/products/:id/edit` to `/:id/02`.

```elixir
 Original                 Rewritten     Result (product_id: 88, 89, 90)
 /products                =>     /01     =>    /01
 /products/:id/edit       => /:id/02     => /88/02, /89/02, /90/02 etc...
 /products/:id/show/edit  => /:id/03     => /88/03, /89/03, /90/03 etc...
```

[Cloak Documentation](https://hexdocs.pm/routex/Routex.Extension.Cloak.html)
