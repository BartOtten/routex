defmodule Routex.Branching do
  @moduledoc """
   Provides a function to build branched variants of macro's
  """

  alias Routex.Utils

  require Logger

  @doc """
  Takes a list of match patterns and creates the AST for branching variants for
  all arities of `macro` in `module` by wrapping them in a `case` statement.


  ** Args **

  - `patterns`: the match patterns to be used as case clauses
  - `match_binding`: ast inserted as `case [match_binding] do`
  - `module`: the module name
  - `macro`: the macro name
  - `opts`: list of options


  ** Options **
  - `arities`: a list of arities to transform, default: all arities
  - `as`: name of the branching variant. default: the macro name
  - `arg_post`: function to calculate the replaced argument position. default: 0

  The clauses and arguments can be transformed by providing MFA's. The
  transformers receive as arguments the `pattern`, the `banched arg` and any
  other argument provided in `a`.

  - `clause_transformer`: {m,f,a}. transforms a pattern; used as case clause in the macro body.
  - `arg_transformer`: {m,f,a}.  transforms a branched argument; used in the macro body.

  ** Example **

  We want to create a branching variant of the `url` macro in `Phoenix,.VerifiedRoutes` module. The original
  macro generates code that simply prints the given path argument, but we want to it to write multiple clauses and
  prefix the given argument based on the clause.

    defmacro url(path, opts \\ []) do -> quote do IO.puts(path) end

  Given this code:

    defmodule MyMod do
      def transform_arg(pattern, arg, extra), do: "/" <> extra <> "/europe/" <> pattern <> "/" <> arg end
    end

    patterns = ["en", "nl"]
    match_binding = var!(external_var)
    arg_pos = fn arity -> arity - 1 end)
    arg_transformer = {MyMod, transform_arg, ["my_extra"]}
    opts = [as: :url, orig: :url_original, arg_pos: arg_pos, arg_transformer: arg_transformer]

    branch_macro(patterns, match_binding, OriginalModule, :url, opts)

  A new macro is build which outputs the AST of the original macro, wrapped in a case clause given transformed arguments.

    defmacro url(path, opts \\ []) do
  	  quote do
  	    case external_var do
  			 "en" -> Original.Module.url( "/" <> "my_extra" <> "/europe/en/" <> path, opts)
  			 "nl" -> Original.Module.url("/" <> "my_extra" <> "/europe/nl/" <> path, opts)
  		 end
       end
     end


  For more examples, please see the test module `Routex.BranchingTest`.
  """

  def branch_macro(
        patterns,
        match_binding,
        module,
        macro,
        opts \\ []
      )
      when is_list(patterns) and
             is_atom(module) and
             is_atom(macro) and
             is_list(opts) do
    patterns = Enum.map(patterns, &Macro.escape/1)
    as = Keyword.get(opts, :as, macro)
    orig_macro = Keyword.get(opts, :orig, macro)
    arities = Keyword.get(opts, :arities) || get_arities!(module, macro)

    ## Print a message to make developers aware of branched macro's.
    arities_str =
      if length(arities) == 1,
        do: "#{hd(arities)}",
        else: "{#{Enum.join(arities, ",")}}"

    mod_name = module |> Module.split() |> Enum.join(".")

    Utils.print(
      "Generate branching variant of: #{mod_name}.#{macro}/#{arities_str} => #{as}/#{arities_str}"
    )

    for arity <- arities do
      # The value of option :arg_pos is at this point a function which defines
      # the argument (position) which should be branched. Anonymous functions
      # can't enter the world of AST. That's why we evaluate :arg_pos at this
      # point and replace it with the resulting value.
      # Furthermore, we subtract 1 to make it a 0-based index value.
      args = Macro.generate_arguments(arity, __MODULE__)
      opts = Keyword.update(opts, :arg_pos, 0, &(&1.(arity) - 1))

      quote do
        require Routex.Branching

        defmacro unquote(orig_macro)(unquote_splicing(args)) do
          Routex.Branching.build_default(
            unquote(module),
            unquote(macro),
            unquote(args)
          )
        end

        defmacro unquote(as)(unquote_splicing(args)) do
          Routex.Branching.build_case(
            unquote(patterns),
            unquote(match_binding),
            unquote(module),
            unquote(macro),
            unquote(args),
            unquote(opts |> Macro.escape())
          )
        end
      end
    end
  end

  defp get_arities!(module, macro) do
    :macros |> module.__info__() |> Keyword.get_values(macro)
  rescue
    ArgumentError ->
      module |> Module.definitions_in(:defmacro) |> Keyword.get_values(macro)
  end

  @doc false
  def build_default(module, macro, args) do
    quote do
      unquote(module).unquote(macro)(unquote_splicing(args))
    end
  end

  @doc false
  def build_case(
        patterns,
        match_binding,
        module,
        macro,
        args,
        opts
      ) do
    clause_transformer = Keyword.get(opts, :clause_transformer)
    argument_transformer = Keyword.get(opts, :argument_transformer)
    branched_arg_pos = Keyword.get(opts, :arg_pos, 0)
    branched_arg = Enum.at(args, branched_arg_pos)

    clauses =
      for pattern <- patterns do
        clause =
          if clause_transformer do
            {cm, cf, ca} = clause_transformer
            apply(cm, cf, [pattern, branched_arg | ca])
          else
            pattern
          end

        if clause == :skip do
          []
        else
          arg =
            if argument_transformer do
              {am, af, aa} = argument_transformer
              apply(am, af, [pattern, branched_arg | aa])
            else
              branched_arg
            end

          if arg == :skip do
            []
          else
            recomposed_args = List.replace_at(args, branched_arg_pos, arg)

            quote do
              unquote(clause) ->
                unquote(module).unquote(macro)(unquote_splicing(recomposed_args))
            end
          end
        end
      end
      |> List.flatten()
      |> Enum.uniq_by(fn {:->, [],
                          [
                            [clause],
                            _
                          ]} ->
        clause
      end)

    if clauses == [] do
      quote do
        unquote(module).unquote(macro)(unquote_splicing(args))
      end
    else
      quote do
        case unquote(match_binding) do
          unquote(clauses)
        end
      end
    end
  end
end
