# `Routex.Extension.Localize.Registry`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/localize/registry.ex#L1)

Pre-generated locale registry shipped with Routex.
Generated from IANA Language Subtag Registry.

It provides validation and  display name lookups.

**Examples:**
```iex
iex> alias Routex.Extension.Localize.Registry
iex> Registry.language("nl-BE")
%{descriptions: ["Dutch", "Flemish"], type: :language}

iex> Registry.region("nl-BE")
%{descriptions: ["Belgium"], type: :region}

iex> Registry.language?("zz")
false

iex> Registry.region?("BE")
true
```

# `cctld?`

# `language`

# `language`

# `language?`

# `region`

# `region`

# `region?`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
