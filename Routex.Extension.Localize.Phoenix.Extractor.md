# `Routex.Extension.Localize.Phoenix.Extractor`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/extractor.ex#L1)

Extracts locale information from various sources. Handles both `Plug.Conn`
structs and map inputs.

Supports languages and regions defined in the [IANA Language Subtag
Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)

### Sources
List of sources to examine for this field.

* `:accept_language` examines the `accept-language` header.
* `:body` uses `body_params`; useful when using values in API bodies.
* `:cookie` uses the request cookie(s)
* `:host` examines the hostname e.g `en.example.com` and `example.nl`. Returns the first match..
* `:path` uses `path_params` such as `/:locale/products/`
* `:query` uses `query_params` such as `/products?locale=en-US`
* `:route` uses the (precompiled) route attributes.
* `:session` uses the session
* `:assigns` uses the assigns stored in connection of socket

### Params
List of keys in a source to examine. Defaults to the name of the field with
fallback to `locale`.

# `do_extract_from_source`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/extractor.ex#L40)

# `extract_from_source`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/extractor.ex#L36)

```elixir
@spec extract_from_source(Plug.Conn.t() | map(), atom(), String.t(), keyword()) ::
  String.t() | nil
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
