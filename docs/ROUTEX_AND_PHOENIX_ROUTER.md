# How Routex and Phoenix Router Work Together: A Blueprint for Understanding

<small>
 All code on this page is for illustration purpose only. It is incorrect and
 should not be used.
</small>

How Routex, its extensions, and the Phoenix Router work together can be better
understood through an analogy. As the saying goes, "a picture is worth a
thousand words," this document also includes an illustrative blueprint.


## Anology: the housing project

Imagine you're a *real estate developer* planning to build several houses. You
have a general vision for the houses (your route definitions in `route.ex`) and
some specific ideas about their style and features (your Routex configuration).

```
# routes
/products
/products/:id

# config
alternatives: %{
    "/fr" => %{name: "French"},
    "/es" => %{name: "Spanish"}
}
```

Routex is the *architect*. It takes your vision (route definitions) and
preferences (Routex config) and creates detailed blueprints.

Routex extensions are the *architect's specialized tools*. These tools allow the
architect to refine and customize the blueprints. Without them, the architect
could only create basic, unmodified plans.

```
# input
[
%Route{path: "/products"}
%Route{path: "/products/:id"}
]

# output after transformation by Alternatives extension
[
%Route{path: "/fr/products",      metadata: %{name: "French"}},
%Route{path: "/fr/products/:id",  metadata: %{name: "French"}},
%Route{path: "/es/products",      metadata: %{name: "Spanish"}},
%Route{path: "/es/products/:id",  metadata: %{name: "Spanish"}}
]
```

Once the blueprints are finalized, they're handed off to the *construction
company*: Phoenix Router. Phoenix Router builds the actual houses (your routes)
according to the architect's precise specifications. The blueprints are
perfectly formatted for Phoenix Router, ensuring a smooth construction process.

```
# note: incorrect pseudo code

if match?("/fr/products"      ), do: ProductLive, :index, metadata: ["French"]
if match?("/fr/products/" <> id), do: ProductLive, :show,  metadata: ["French"]
if match?("/es/products"      ), do: ProductLive, :index, metadata: ["Spanish"]
if match?("/es/products/" <> id), do: ProductLive, :show,  metadata: ["Spanish"]
```

This explains the first key concept:

> **Routex generates blueprints from your route definitions and configuration,
> ready for Phoenix Router to build the actual routes.**

Because Routex is the architect, it has intimate knowledge of the house designs.
This allows it to create perfectly matching accessories, like custom-designed
sunshades or smart garage doors. These are *additional* features that enhance
the houses built by Phoenix Router, adding convenience and functionality.

```
# generated convenient functions
defmodule Helpers do
  def alternatives("/products") do
    [
      %Route{path: "/fr/products", name: "French"},
      %Route{path: "/es/products", name: "Spanish"}
    ]
  end
end

# your usage
This page is available in:
for alt <- Helpers.alternatives("/products") do
 <.link navigate={alt.path}>{alt.name}<./link>
end

# output
This page is available in:
<a href="/fr/products">French</a>
<a href="/es/products">Spanish</a>
```

This leads to the second key concept:

> **Routex also creates helpful accessory functions that you can use with the
> houses (routes) built by Phoenix Router.** These functions streamline common
> tasks and improve the overall experience.


## Example blueprint

A picture paints a thousand words, or so they say. The blueprint clearly shows
how Routex is middleware, plugged between two stages of Phoenix route generation.

Also shown is the use two co-operating extensions: `Translations` uses the
`:language` attribute set by `Alternatives`.

<pre class="mermaid">
flowchart TD
 subgraph subGraph1["Routex"]
        F["ExampleWeb.RoutexBackend.ex"]
        G["configure/2 callbacks"]
        H["Alternatives.transform/3 callback"]
        I["Translations.transform/3 callback"]
        J["create_helpers/3 callbacks"]
     K["ExampleWeb.Router.RoutexHelpers"]
  end
  subgraph subGraph0["Phoenix"]
        A["ExampleWeb.Router.ex"]
        B["Convert to Phoenix.Routes.Route structs"]
        C["Generate route functions"]
        D["ExampleWeb.Router"]
  end
  A -- "/products/:id" --> B
  B -- "%{path: /products/:id}" --> H
  F -- "extensions: [Alternatives, Translations]" --> G
  G --> H
  H -- "%{path: ..., attrs: %{lang: fr}}
       %{path: ..., attrs: %{lang: es}}" --> I
  I -- "%{path: /produit/:id, attrs: ...}
       %{path: /producto/:id, attrs: ...}" --> C & J
  C -- "def match?(/produit/:id), do: ProductController
      def match?(/producto/:id), do: ProductController" --> D
  J -- "def alternatives(/products/:id) do
        %{path: /produit/:id, attrs: %{lang: fr}}
        %{path: /producto/:id, attrs: %{lang: es}}
      end" --> K

  F:::routex
  G:::routex
  H:::routex
  I:::routex
  J:::routex
  K:::routex
  A:::phoenix
  B:::phoenix
  C:::phoenix
  D:::phoenix
 classDef routex  fill:#4d4d4d, stroke:#888, stroke-width:2px, color:#ffffff
 classDef phoenix  stroke-width:1px, stroke-dasharray: 0, stroke:#616161, fill:#FF6D00, color:#424242
 style subGraph0 fill:#FFFFFF, stroke:#757575
 style subGraph1 fill:#FFFFFF, stroke:#757575
</pre>


## Conclusion
Phoenix Router and Routex, along with its extensions, form a powerful
partnership that empowers you to build any route in your web application. Routex
expertly designs the intricate pathways of your application's URLs, while
Phoenix Router flawlessly constructs them, ensuring a smooth and efficient user
experience.
