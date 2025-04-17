## Summary

From its humble beginnings as PhxAltRoutes—a proof-of-concept for localized
routing in Phoenix—to the modular, extension-driven framework that Routex is
today, this is the story of how community feedback, design constraints, and the
immutable spirit of Elixir shaped a next-generation routing library. Along the
way, we’ll trace the key design pivots that led to Routex’s pluggable core,
shim-based integration, and stateless, inspectable architecture.

## Origins: PhxAltRoutes and the Rise of Localized Routing

The concept of compile-time generation of localized and translated routes (using
Gettext) first emerged back in March 2021 when I, Bart Otten, [first posted about
PhxAltRoutes](https://elixirforum.com/t/reality-check-your-library-idea/32840/30)
to be followed by a post in Februari 2022 [asking the community for feedback and
collaboration](https://elixirforum.com/t/library-for-localized-multilingual-routes-in-phoenix/46233).

The early review phase resulted in PhxAltRoutes being renamed **Phoenix
Localized Routes (PLR)** to better reflect its main use case and the
introduction of the PhxAltRoutes-inspired **Cldr-Routes** in late March 2022 by
the maintainer of Cldr.

With two libs in production, developers could write:

```elixir
# Import localized route macros
use Phoenix.LocalizedRoutes  # or Cldr.Routes

localize do
  get "/pages/:page", PageController, :show
  resources "/users", UserController
end
```

And have their routes expanded to localize routes at compile time. Great!


## Localized Routes: Promise and Pain Points

But as usage grew, so did the cracks:

1. **Code Duplication**: PLR and Cldr-Routes forked bits of Phoenix’s router
   internals, making every upstream Phoenix update a potential breaking change.
2. **Monolithic Design**: Projects needing PLR for one feature faced the full
   library, leading to bloat. Cldr-Routes -being an extension itself- needs the
   Cldr base library to function. If you are not (yet) into the Cldr ecosystem,
   I consider it a heavy weight to pull in and configure.
3. **One-Size-Fits-All**: From greenfield apps to legacy codebases, each
   project’s needs varied— both PLR and Cldr-Routes don’t or didn't adapt the way
   I envisioned.
4. **Maintenance Overhead**: Every new route feature forced code changes across
   user projects, straining both library and app maintainers.
5. **Stateful Routing**: PLR and Cldr-Routes lean on process state, a mismatch
   with Elixir’s immutable ethos.

These lessons set the stage for a reinvented approach.

## Reinventing (Localized) Routing: Birth of Routex

In early 2023, I sketched out a fresh vision: a **slim core** with **pluggable
extensions**, a name that hinted at both routing and extensibility—**Routex**.

> *“Route + Elixir. Route + Extensions. Route + Extendable—pick your flavor.”*

Key principles emerged:

- **Only What You Need**: A minimal core handles just the essentials; extensions
  add features as needed.
- **Shim, Don’t Copy**: Rather than replicating Phoenix internals, shim public
  APIs and delegates to the official public Phoenix functions, so upstream
  changes flow through automatically.
- **Stateless by Default**: No process state. (Alternative) Route lookup remains
  pure and immutable, fitting Elixir’s design philosophy.
- **Inspectability**: Route definitions flow through **opts** and **structs**,
  making callbacks transparent and chainable.
- **Configuration-Driven**: Add features by toggling extensions in config—no
  code scattering.

## Core Architecture and Extensibility

At the heart of Routex is a processing pipeline: It takes the routes and a list
of extensions and reduces the list of extensions with the routes as argument.

As a result, the extensions -implementing one or more of four well-defined
callbacks: `configure/2`, `transform/3`, `post_transform/3`, and
`create_helpers/3`- receive inspectable route structs and opts, allowing
transparent, composable modifications.

Meanwhile, `Routex.Attrs` provides a shared metadata store so extensions like
`Routex.Extension.Localize.Phoenix.Runtime` (for runtime locale detection) and
`Routex.Extension.Translations` (for translated route paths) can cooperate
without stepping on each other’s toes.

## Immutability and Pattern Matching in Action

Under the hood, Routex uses immutable pattern matching to transform
normal routes into branch aware (auto-scoping) routes.

This is different from some other libraries that use mutable (process-bound)
state. It's a subtle difference, but one that matters.


```elixir
# Pseudo code: The mutable way (aka: standard Javascript demo)

# Somewhere in your templates a link to 'products' in the current scope.
<link href=~p"/products">Products</link> # => /products

for locale <- ["en", "fr"] do
  put_locale(locale)  # setting state
  <link href=~p"/products">{locale}</link>
end

# Somewhere in a used component a link to products...guess in which scope.
<link href=~p"/products">Products</link>

```

Routex does it different, pure. At compile time it generates url pattern
matching helpers. As a result, no state is involved and Routex is not coupled to
the current process.

```elixir
# Pseudo code: The immutable Routex way (simplified)

# Somewhere in your templates a link to products in the current scope.
<link href=~p"/products">Products</link> # => /products

# inefficient use for demonstration purpose
for locale <- ["en", "fr"] do
  alt = alternatives(@url)[locale]
  <link href=alt.slug>{locale}</link>
end

# Somewhere in a used component a link to 'products' in the current scope.
<link href=~p"/products">Products</link>
```

No hidden state. No surprises. Just Elixir.


## Configuration above all else
The development of Routex has a mission credo: "Simple by default, powerful when
needed". Setup should be minimal, yet you should be able to adapt Routex to your
project instead of the other way around like previous attempts.

For example, the `Routex.Extension.VerifiedRoutes` lets you customize the sigil
letter and helper names. These can be set to match Phoenix’s defaults -to avoid
template churn- or those of Cldr-Routes -to ease migration-. As such, a project
can opt into (locale) branch aware Verified Routes by Routex seamlessly—no hard
forks in your code.


## Localization Reimagined with Localize.Phoenix

With the groundwork laid, I revisited the original primary use case early 2025:
localization. This time however, it was just an optional use case out of
multiple supported by Routex instead of the only one. Its implementation is a
testament to the design choices made upfront.

`Routex.Extension.Localize.Phoenix` offers:

- Automated Plug and LiveView integration at runtime.
- A minimal locale registry based on IANA standards.
- Customizable locale detection strategies.
- Support for multiple locale backends.
- All configured via a few entries in config.exs, with no changes to route
  definitions or templates.


## Community Feedback and the Road Ahead
Looking forward, the vision remains clear: empower developers to craft custom
routing logic with minimal friction, leverage Elixir’s immutability, and foster
a vibrant ecosystem of extensions. Routex is designed to grow with your
application, not weigh it down.

> *“Routing should adapt to every project’s needs, without forcing projects to
> adapt to the router.”*

And that’s how PhxAltRoutes evolved, lessons were learned, and Routex was
born—ready to supercharge Phoenix routing with extension-driven superpowers!

*— Bart Otten*

