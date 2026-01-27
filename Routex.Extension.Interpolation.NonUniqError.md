# `Routex.Extension.Interpolation.NonUniqError`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/extension/interpolation.ex#L59)

Raised when a list of routes contains routes with the same path and verb.

```elixir
[%Route{
  path: "/foo"
  verb: :get},
%Route{
  path: "/foo"
  verb: :post}, # <-- different
%Route{
  path: "/foo"
  verb: :get} # <-- duplicate
]
```

Solution: use a combination of interpolated attributes that form a unique set.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
