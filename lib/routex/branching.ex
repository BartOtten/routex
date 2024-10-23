defmodule Routex.Branching do
  @moduledoc """
   Provides a set of functions to build branched variants of macro's
  """

  alias Routex.Utils

  require Logger

  @doc """
  Takes a list of match patterns and creates the AST for branching variants
  for all arities of `macro` in `module`.


  ** Args
  - match_binding: the argument for the case clause
  - patterns: the match patterns of the case clause
  - transformer: transforms a original arguments value

  ** Example

  We want to create a branching variant of the `url` macro in `Phoenix,.VerifiedRoutes` module. The original
  macro generates code that simply prints the given path argument, but we want to it to write multiple clauses and
  prefix the given argument based on the clause.

    defmacro url(path, opts \\ []) do -> quote do IO.puts(path) end

  Given this code:

    patterns = ["en", "nl"]
    match_binding = var!(external_var)
    arg_transformer = fn pattern, arg -> "europe/" <> pattern <> "/" <> arg end

    branch_macro(patterns, match_binding, arg_transformer, OriginalModule, :url,
  	as: :url,
  	orig: :url_original,
  	arg_pos: fn arity -> arity - 1 end)

  A new macro is build which outputs the AST of the original macro, wrapped in a case clause given transformed arguments.

    defmacro url(path, opts \\ []) do
  	 quote do
  	   case match_binding do
  			 "en" -> Original.Module.url("europe/en/" <> url, opts)
  			 "nl" -> Original.Module.url("europe/nl/" <> url, opts)
  		 end
   end
  end
  """

  def branch_macro(
        patterns,
        match_binding,
        clause_transformer,
        argument_transformer,
        module,
        fun,
        opts \\ []
      )
      when is_list(patterns) and
             is_atom(module) and
             is_atom(fun) and
             is_list(opts) do
    as_fun = Keyword.get(opts, :as, fun)
    orig_fun = Keyword.get(opts, :orig, fun)
    arities = Keyword.get(opts, :arities) || get_arities!(module, fun)
    patterns = Enum.map(patterns, &Macro.escape/1)

    ## Print a message to make developers aware of branched macro's.
    arities_str =
      if length(arities) == 1,
        do: "#{hd(arities)}",
        else: "{#{Enum.join(arities, ",")}}"

    mod_name = module |> Module.split() |> Enum.join(".")

    Utils.print(
      "Generate branching variant of: #{mod_name}.#{fun}/#{arities_str} => #{as_fun}/#{arities_str}"
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

        defmacro unquote(orig_fun)(unquote_splicing(args)) do
          Routex.Branching.build_default(
            unquote(module),
            unquote(fun),
            unquote(args)
          )
        end

        defmacro unquote(as_fun)(unquote_splicing(args)) do
          Routex.Branching.build_case(
            unquote(patterns),
            unquote(match_binding),
            unquote(Macro.escape(clause_transformer)),
            unquote(Macro.escape(argument_transformer)),
            unquote(module),
            unquote(fun),
            unquote(args),
            unquote(opts)
          )
        end
      end
    end
  end

  defp get_arities!(module, fun) do
    :macros |> module.__info__() |> Keyword.get_values(fun)
  rescue
    ArgumentError ->
      module |> Module.definitions_in(:defmacro) |> Keyword.get_values(fun)
  end

  def build_default(module, fun, args) do
    quote do
      unquote(module).unquote(fun)(unquote_splicing(args))
    end
  end

  def build_case(
        patterns,
        match_binding,
        {cm, cf, ca} = _clause_transformer,
        {am, af, aa} = _argument_transformer,
        module,
        fun,
        args,
        opts
      ) do
    branched_arg_pos = Keyword.get(opts, :arg_pos, 0)
    branched_arg = Enum.at(args, branched_arg_pos)

    clauses =
      for pattern <- patterns do
        recomposed_clause = apply(cm, cf, [pattern, branched_arg | ca])

        if recomposed_clause == :skip do
          []
        else
          recomposed_arg = apply(am, af, [pattern, branched_arg | aa])
          recomposed_args = List.replace_at(args, branched_arg_pos, recomposed_arg)

          if recomposed_arg == :skip do
            []
          else
            quote do
              unquote(recomposed_clause) ->
                unquote(module).unquote(fun)(unquote_splicing(recomposed_args))
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
        unquote(module).unquote(fun)(unquote_splicing(args))
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
