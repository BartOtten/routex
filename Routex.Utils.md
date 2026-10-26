# `Routex.Utils`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/utils.ex#L1)

Provides an interface to functions which can be used in extensions.

# `alert`

Prints an alert. Should be used when printing critical alerts in
the terminal during compile time.

# `assign_module`

```elixir
@spec assign_module() :: module()
```

Returns the module to use for LiveView assignments

# `ensure_compiled!`

```elixir
@spec ensure_compiled!(module()) :: module()
```

Backward compatible version of `Code.ensure_compiled!/1`

# `get_attribute`

Test env aware variant of Module.get_attribute. Delegates to
`Module.get_attribute/3` in non-test environments. In test environment it
returns the result of `Module.get_attribute/3` or an empty list when the
module is already compiled.

# `get_branch_leaf`

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

```elixir
@spec get_branch_leaf_from_assigns(map(), module(), module()) :: integer()
```

Returns the branch leaf from assigns.

# `get_helper_ast`

```elixir
@spec get_helper_ast(caller :: Routex.Types.env()) :: Routex.Types.ast()
```

Returns the AST to get the current branch leaf from process dict or from  assigns, conn or socket
based on the available variables in the `caller` module.

# `print`

```elixir
@spec print(module(), input :: iodata()) :: :ok
```

Prints an indented text. Should be used when printing messages in
the terminal during compile time.

# `process_put_branch`

```elixir
@spec process_put_branch(branch :: [integer(), ...]) :: integer()
@spec process_put_branch(branch :: integer()) :: integer()
```

Helps setting the branch in the process dictionary.

**Example: As dispatch target**

```elixir
dispatch_targets: [{Routex.Utils, :process_put_branch, [[:attrs, :__branch__]]}]
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
