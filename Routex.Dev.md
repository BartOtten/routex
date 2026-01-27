# `Routex.Dev`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/dev.ex#L2)

Provides functions to aid during development

# `inspect_ast`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/dev.ex#L12)

```elixir
@spec inspect_ast(ast :: Macro.t(), list()) :: Macro.t()
```

`Macro.escape/1` and `IO.inspect/2` the given input. Options are
passed through to `IO.inspect`. Returns the input.

# `print_ast`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/dev.ex#L32)

Helper function to inspect AST as formatted code. Returns the
input.

## Examples

    iex> ast = quote do: Map.put(my_map, :key, value)
    iex> print_ast(ast)
    Map.put(my_map, :key, value)
    ...actual AST...

---

*Consult [api-reference.md](api-reference.md) for complete listing*
