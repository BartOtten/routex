# `Routex.Extension.Localize.Phoenix.Runtime`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L1)

This extension provides:

- A Plug (`plug/3`) to update the connection with locale attributes and store them
  in the session. Enabled via `Routex.Extension.Plugs`.
- A LiveView lifecycle hook (`handle_params/4`) to update the socket with
  locale-related attributes. Enabled via `Routex.Extension.LiveViewHooks`.

Both are optimized for performance.

Locale values can be sourced independently from locations like:

- Pre-compiled route attributes
- The `Accept-Language` header sent by the client (`fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7`)
- Query parameters (`?lang=fr`)
- Hostname (`fr.example.com`)
- Path parameters (`/fr/products`)
- Assigns (`assign(socket, [locale: "fr"])`)
- Body parameters
- Stored cookie
- Session data

Runtime detection is configured by specifying sources for locale attributes
(`:locale`, `:language`, `:region`).

#### Locale Attributes and Their Sources

Each attribute (`:locale`, `:language`, `:region`) can have its own list of
sources and parameter names, where the parameter name is the key to get from
the source. The parameter should be provided as a string.

##### Supported Sources
- `:accept_language`: From the header sent by the client (e.g. `fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7`)
- `:assigns`: From conn and socket assigns.
- `:route`: From precompiled route attributes.
- `:body`: From request body parameters.
- `:cookie`: From request cookies.
- `:host`: From the hostname (e.g., `en.example.com`).
- `:path`: From path parameters (e.g., `/:lang/users`).
- `:query`: From query parameters (e.g., `?locale=de`).
- `:session`: From session data.

##### Default Configuration

The default sources for each attribute are:
`[:query, :session, :cookie, :accept_language, :path, :assigns, :route]`.

##### Overriding Detection Behavior

You can customize sources and parameters per attribute:

**Examples:**
```elixir
# In your Routex backend module
locale_sources: [:query, :session, :accept_language], # Order matters
locale_params: ["locale"], # Look for ?locale=... etc

language_sources: [:path, :host],
language_params: ["lang"], # Look for /:lang/... etc

region_sources: [:route] # Only use region from precompiled route attributes
# region_params defaults to ["region"]
```

# `conn`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L84)

```elixir
@type conn() :: Plug.Conn.t()
```

# `params`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L87)

```elixir
@type params() :: %{optional(String.t()) =&gt; any()}
```

# `plug_opts`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L88)

```elixir
@type plug_opts() :: keyword()
```

# `socket`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L85)

```elixir
@type socket() :: Phoenix.LiveView.Socket.t()
```

# `url`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L86)

```elixir
@type url() :: String.t()
```

# `call`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L187)

```elixir
@spec call(conn(), plug_opts()) :: conn()
```

Plug callback to detect and assign locale attributes to the connection.

Examines configured sources (params, session, headers, etc.), updates
`conn.assigns`, merges attributes into `conn.private.routex.attrs`, and
persists relevant attributes in the session.

# `configure`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L97)

```elixir
@spec configure(Routex.Types.opts(), Routex.Types.backend()) :: Routex.Types.opts()
```

Checks for invalid sources

# `handle_params`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/phoenix/localize_phoenix_runtime.ex#L155)

```elixir
@spec handle_params(params(), url(), socket()) :: {:cont, socket()}
```

LiveView `handle_params/4` callback hook.

Detects locale settings based on URL, params, and socket state, then updates
the socket assigns and Routex attributes.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
