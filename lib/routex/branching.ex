defmodule Routex.Branching do
  @moduledoc """
  Builds branched variants of macros by wrapping them in case statements.

  This module helps create alternative implementations of macros that dispatch
  based on runtime patterns, useful for multi-locale routes, feature flags,
  and other branching logic.
  """

  alias Routex.Utils

  require Logger

  @type pattern :: any()
  @type match_ast :: Macro.t()
  @type transformer_spec :: function()

  @migrate_options [
    {:as, :name_branched},
    {:orig, :name_passthrough},
    {:arg_pos, :param_position}
  ]

  @doc """
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

        defmacro url(path, opts \\ []) do
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

        defmacro branched_macro(arg1, opts \\ []) do
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
  """

  @spec branch_macro(module(), atom(), match_ast(), [pattern()], Keyword.t()) :: [Macro.t()]
  def branch_macro(module, macro_name, match_binding, patterns, opts \\ [])

  def branch_macro(
        module,
        macro,
        match_binding,
        patterns,
        opts
      )
      when is_atom(module) and
             is_atom(macro) and
             is_list(patterns) and
             is_list(opts) do
    opts = migrate_deprecated(opts)
    escaped_patterns = Enum.map(patterns, &Macro.escape/1)
    name_branched_macro = Keyword.get(opts, :name_branched)
    name_passthrough_macro = Keyword.get(opts, :name_passthrough)
    arities = Keyword.get(opts, :arities) || get_arities!(module, macro)

    log_macro_generation(module, macro, name_branched_macro, arities)

    prelude = build_prelude(escaped_patterns)

    macros =
      build_macro_definitions(
        module,
        macro,
        arities,
        match_binding,
        name_branched_macro,
        name_passthrough_macro,
        opts
      )

    [prelude | macros]
  end

  # credo:disable-for-next-line
  # TODO: Remove in newer version, deprecated param order
  @spec branch_macro([pattern()], match_ast(), module(), atom(), Keyword.t()) :: [Macro.t()]
  def branch_macro(
        patterns,
        match_binding,
        module,
        macro,
        opts
      )
      when is_list(patterns) and
             is_atom(module) and
             is_atom(macro) and
             is_list(opts) do
    Routex.Utils.alert(
      "Deprecated",
      "Using deprecated order of argument while using `Routex.Branching.branch_macro/{4,5}`"
    )

    branch_macro(module, macro, match_binding, patterns, opts)
  end

  defp migrate_deprecated(opts) do
    for {old, new} <- @migrate_options, reduce: opts do
      opts ->
        {old_value, new_opts} = Keyword.pop(opts, old)

        if new_opts != opts do
          Routex.Utils.alert(
            "Deprecated",
            "An extension is using deprecated option #{inspect(old)} while calling `Routex.Branching.branch_macro/{4,5}`"
          )

          Keyword.put(new_opts, new, old_value)
        else
          opts
        end
    end
  end

  defp build_macro_definitions(
         module,
         macro,
         arities,
         match_binding,
         name_branched_macro,
         name_passthrough_macro,
         opts
       ) do
    for arity <- arities do
      args = Macro.generate_arguments(arity, __MODULE__)

      normalized_opts =
        Keyword.update(opts, :param_position, 0, &normalize_param_position_option(&1, arity))

      quote do
        defmacro unquote(name_passthrough_macro)(unquote_splicing(args)) do
          Routex.Branching.build_default(
            unquote(module),
            unquote(macro),
            unquote(args)
          )
        end

        defmacro unquote(name_branched_macro)(unquote_splicing(args)) do
          Routex.Branching.build_case(
            unquote(module),
            unquote(macro),
            unquote(args),
            unquote(match_binding),
            branch_patterns(),
            unquote(Macro.escape(normalized_opts))
          )
        end
      end
    end
  end

  @doc false
  def build_default(module, macro, args) do
    quote do
      unquote(module).unquote(macro)(unquote_splicing(args))
    end
  end

  @doc false
  def build_case(
        module,
        macro,
        args,
        match_binding,
        patterns,
        opts
      ) do
    clause_transformer = Keyword.get(opts, :clause_transformer)
    argument_transformer = Keyword.get(opts, :argument_transformer)

    # credo:disable-for-next-line
    # TODO: Remove :arg_pos in newer version, deprecated param order
    branched_param_position = Keyword.get(opts, :arg_pos) || Keyword.get(opts, :param_position, 0)
    branched_arg = Enum.at(args, branched_param_position)

    case build_clauses(
           module,
           macro,
           args,
           patterns,
           branched_arg,
           branched_param_position,
           clause_transformer,
           argument_transformer
         ) do
      [] ->
        build_default(module, macro, args)

      clauses ->
        quote do
          case unquote(match_binding) do
            unquote(clauses)
          end
        end
    end
  end

  defp build_prelude(escaped_patterns) do
    quote do
      require Routex.Branching

      defp branch_patterns, do: unquote(escaped_patterns)
    end
  end

  defp build_clauses(
         module,
         macro,
         args,
         patterns,
         branched_arg,
         branched_param_position,
         clause_transformer,
         argument_transformer
       ) do
    patterns
    |> Enum.map(
      &build_clause(
        module,
        macro,
        args,
        &1,
        branched_arg,
        branched_param_position,
        clause_transformer,
        argument_transformer
      )
    )
    |> List.flatten()
    |> deduplicate_clauses()
  end

  defp build_clause(
         module,
         macro,
         args,
         pattern,
         branched_arg,
         branched_param_position,
         clause_transformer,
         argument_transformer
       ) do
    with clause <- transform_clause(pattern, branched_arg, clause_transformer),
         false <- clause in [:skip, :noop],
         arg <- transform_argument(pattern, branched_arg, argument_transformer),
         false <- arg in [:skip, :noop] do
      recomposed_args = List.replace_at(args, branched_param_position, arg)

      quote do
        unquote(clause) ->
          unquote(module).unquote(macro)(unquote_splicing(recomposed_args))
      end
    else
      true -> []
    end
  end

  defp transform_clause(pattern, _branched_arg, nil), do: pattern

  defp transform_clause(pattern, branched_arg, fun) when is_function(fun) do
    fun.(pattern, branched_arg)
  end

  # credo:disable-for-next-line
  # TODO: Remove in newer version
  defp transform_clause(pattern, branched_arg, {module, function, extra_args}) do
    warn_deprecated_transform(module, function, extra_args)
    apply(module, function, [pattern, branched_arg])
  end

  defp transform_argument(_pattern, branched_arg, nil), do: branched_arg

  defp transform_argument(pattern, branched_arg, fun) when is_function(fun) do
    fun.(pattern, branched_arg)
  end

  # credo:disable-for-next-line
  # TODO: Remove in newer version
  defp transform_argument(pattern, branched_arg, {module, function, extra_args}) do
    warn_deprecated_transform(module, function, extra_args)
    apply(module, function, [pattern, branched_arg])
  end

  defp deduplicate_clauses(clauses) do
    clauses
    |> Enum.uniq_by(&extract_clause_pattern/1)
  end

  defp warn_deprecated_transform(module, function, extra_args) do
    Routex.Utils.alert("Deprecated", """
    Please use the new notation for the transformer options
    when using Routex.Branching in your extensions.

    old: {#{inspect(module)}, #{inspect(function)}, #{inspect(extra_args)}}
    new:  &#{inspect(module)}.#{function}/2
    """)

    if extra_args != [],
      do:
        Routex.Utils.print("""
        The extra args #{inspect(extra_args)} should be put static in the transformer instead
        of passing them as extra arguments.
        """)
  end

  defp extract_clause_pattern({:->, _meta, [[clause], _body]}), do: clause
  defp extract_clause_pattern(other), do: other

  defp normalize_param_position_option(pos, arity) do
    case pos do
      fun when is_function(fun) -> fun.(arity) - 1
      pos when is_integer(pos) -> pos
      nil -> 0
    end
  end

  defp get_arities!(module, name_macro) do
    :macros
    |> module.__info__()
    |> Keyword.get_values(name_macro)
  rescue
    ArgumentError ->
      module
      |> Module.definitions_in(:defmacro)
      |> Keyword.get_values(name_macro)
  end

  defp log_macro_generation(module, name_macro, name_branched, arities) do
    arities_str = format_arities(arities)
    module_name = module |> Module.split() |> Enum.join(".")

    Utils.print(
      __MODULE__,
      "Generate branching variant: #{module_name}.#{name_macro}/#{arities_str} => #{name_branched}/#{arities_str}"
    )
  end

  defp format_arities([single_arity]), do: "#{single_arity}"
  defp format_arities(arities), do: "{#{Enum.join(arities, ",")}}"
end
