# `Routex.Branching`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/branching.ex#L1)

Builds branched variants of macros by wrapping them in case statements.

This module helps create alternative implementations of macros that dispatch
based on runtime patterns, useful for multi-locale routes, feature flags,
and other branching logic.

# `match_ast`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/branching.ex#L13)

```elixir
@type match_ast() :: Macro.t()
```

# `pattern`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/branching.ex#L12)

```elixir
@type pattern() :: any()
```

# `transformer_spec`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/branching.ex#L14)

```elixir
@type transformer_spec() :: function()
```

# `branch_macro`
[🔗](https://github.com/BartOtten/routex/blob/v1.3.2/lib/routex/branching.ex#L163)

```elixir
@spec branch_macro(module(), atom(), match_ast(), [pattern()], Keyword.t()) :: [
  Macro.t()
]
```

```elixir
@spec branch_macro([pattern()], match_ast(), module(), atom(), Keyword.t()) :: [
  Macro.t()
]
```

  Creates branched variants of a macro for all or specified arities.

  Generates new macros that wrap the original macro in a case statement,
  allowing different behavior based on match patterns.

## Arguments

  - `module` - Module containing the original macro
  - `macro` - Name of the original macro
  - `match_binding` - AST that evaluates to the value or AST pattern being matched
  - `patterns` - List of values or AST patterns to match in the case statement
  - `opts` - Configuration options

## Options
  - `arities` - List of specific arities to generate (default: all arities)
  - `name_branched` - Name of the generated branching macro (default: same as `:macro_name`)
  - `name_passthrough` - Name of passthrough macro that defers to the original macro (default: same as `:macro_name`)
  - `param_position` - Function `(arity) -> position` determining which param to branch on (default: 0)

## Transformers

  The transformer functions receive the `pattern` and the `branched_arg` as arguments.

  - `pattern` - The current item from the `patterns` list being processed in this branch - `branched_arg` - The argument at position `param_position` from the macro invocation (the value being branched on)

  - `clause_transformer` - Function signature: `(pattern, branched_arg) -> pattern | :noop`
    - Return a transformed clause pattern to include it in the case statement

  - `argument_transformer` - Function signature: `(pattern, branched_arg) -> transformed_arg | :noop`
    - Return the transformed argument to pass to the original macro

  If either transformer returns `:noop`, the case clause (branch) is not generated.

  ## Examples

  ### Basic Example:  Inserting locale into path segments

  Transform path segments to include locale after the first segment:

      defmodule MyApp. Transformers do
        # Insert locale after first segment:  /products/categories -> /products/[locale]/categories
        def insert_locale(locale_pattern, branched_arg, _extra) do
          case branched_arg do
            [first | rest] -> [first, "/" <> locale_pattern | rest]
            _ -> branched_arg
          end
        end
      end

      defmodule MyApp.Routes do
        require Routex.Branching

        patterns = ["en", "nl", "fr"]
        match_binding = quote do:  var!(locale)

        ast = Routex. Branching.branch_macro(
          Phoenix. VerifiedRoutes,
          :url,
          match_binding,
          patterns,
          name_branched: :url,
          name_passthrough: :original_url,
          argument_transformer: &MyApp.Transformers.insert_locale/2,
        )

        Module.create(__MODULE__, ast, Macro. Env. location(__ENV__))
      end

  Input: `["/products", "/categories"]`

  The generated macro becomes:

      defmacro url(path, opts \ []) do
        quote do
          case var!(locale) do
            "en" -> Phoenix.VerifiedRoutes.url(["/products", "/en", "/categories"], opts)
            "nl" -> Phoenix.VerifiedRoutes.url(["/products", "/nl", "/categories"], opts)
            "fr" -> Phoenix.VerifiedRoutes.url(["/products", "/fr", "/categories"], opts)
          end
        end
      end

  Output paths: `/products/en/categories`, `/products/nl/categories`, `/products/fr/categories`

  ### Advanced Example: With clause and argument transformers

  Transform both the match clause and the argument:

      defmodule MyApp. Advanced do
        allowed_locales = ["en", "nl"]

        # Filter which patterns to include
        def transform_clause(pattern, _arg) do
          if pattern in allowed_locales, do: pattern, else: :noop
        end

        # Insert locale as second segment with prefix
        def transform_argument(locale_pattern, branched_arg) do
          case branched_arg do
            [first | rest] -> [first, "locale_" <> locale_pattern | rest]
            _ -> branched_arg
          end
        end
      end

      patterns = ["en", "nl", "de", "es"]
      match_binding = quote do: var!(locale)
      prefix="/locale_"

      ast = Routex. Branching.branch_macro(
        SomeModule,
        :some_macro,
        match_binding,
        patterns,
        name_branched: :branched_macro,
        clause_transformer: &MyApp.Transformers.transform_clause/2,
        argument_transformer: &MyApp.Transformers.transform_argument/2
      )

  Input: `["/api", "/users"]`

  This generates:

      defmacro branched_macro(arg1, opts \ []) do
        quote do
          case var!(locale) do
            "en" -> SomeModule.some_macro(["/api", "/locale_en", "/users"], opts)
            "nl" -> SomeModule.some_macro(["/api", "/locale_nl", "/users"], opts)
          end
        end
      end

  Output paths: `/api/locale_en/users`, `/api/locale_nl/users`

  Note: "de" and "es" are filtered out by `transform_clause` returning `:noop`.

  For more examples, please see the test module `Routex.BranchingTest`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
