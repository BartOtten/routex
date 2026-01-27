# `Routex.Utils`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L1)

Provides an interface to functions which can be used in extensions.

# `alert`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L39)

Prints an alert. Should be used when printing critical alerts in
the terminal during compile time.

# `assign_module`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L281)

```elixir
@spec assign_module() :: module()
```

Returns the module to use for LiveView assignments

# `ensure_compiled!`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L258)

```elixir
@spec ensure_compiled!(module()) :: module()
```

Backward compatible version of `Code.ensure_compiled!/1`

# `get_attribute`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L218)

Test env aware variant of Module.get_attribute. Delegates to
`Module.get_attribute/3` in non-test environments. In test environment it
returns the result of `Module.get_attribute/3` or an empty list when the
module is already compiled.

# `get_branch_leaf`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L181)

```elixir
@spec get_branch_leaf(
  Routex.Types.route()
  | map()
  | Plug.Conn.t()
  | Phoenix.Socket.t()
  | [integer(), ...]
) :: integer()
```

# `get_branch_leaf_from_assigns`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L136)

```elixir
@spec get_branch_leaf_from_assigns(map(), module(), module()) :: integer()
```

Returns the branch leaf from assigns.

# `get_helper_ast`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L77)

```elixir
@spec get_helper_ast(caller :: Routex.Types.env()) :: Routex.Types.ast()
```

Returns the AST to get the current branch leaf from process dict or from  assigns, conn or socket
based on the available variables in the `caller` module.

# `print`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L17)

```elixir
@spec print(module(), input :: iodata()) :: :ok
```

Prints an indented text. Should be used when printing messages in
the terminal during compile time.

# `process_put_branch`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L63)

```elixir
@spec process_put_branch(branch :: [integer(), ...]) :: integer()
```

```elixir
@spec process_put_branch(branch :: integer()) :: integer()
```

Helps setting the branch in the process dictionary.

**Example: As dispatch target**

```elixir
dispatch_targets: [{Routex.Utils, :process_put_branch, [[:attrs, :__branch__]]}]
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
