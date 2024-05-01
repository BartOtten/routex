defmodule Routex.Branching do
  alias Routex.Utils

  @doc """
  Takes a list of `patterns` and creates AST for a braching variant
  of `function` of `module` by matching on a pattern and rewriting one
  of the arguments.

  ** Example

  		branch_macro(patterns, Phoenix.VerifiedRoutes, :sigil_p,
  			as: :sigil_p,
  			orig: :sigil_o,
  			arg_pos: fn arity -> arity - 1 end
  		)

  defmacro url(url) do -> quote do IO.inspect(url) end

  becomes

  defmacro url(url, opts) do
  quote do case helper do
  "en" -> Original.Module.url("en/" <> url, opts)
  "nl" -> Original.Module.url("nl/" <> url, opts)
  end
  end
  end
  """

  def branch_macro(patterns, match_binding, transformer, module, fun, opts \\ [])
      when is_list(patterns)
					 and is_atom(module)
					 and is_atom(fun)
			and is_list(opts) do
    as_fun = Keyword.get(opts, :as, fun)
    orig_fun = Keyword.get(opts, :orig, fun)
    arities = :macros |> module.__info__() |> Keyword.get_values(fun)

    ## Print a message to make developers aware of branched macro's.
    arities_str =
      if length(arities) == 1,
				 do: "#{hd(arities)}",
				 else: "{#{Enum.join(arities, ",")}}"

    mod_name = module |> Module.split() |> Enum.join(".")
    Utils.print("Generate branching variant of: #{mod_name}.#{fun}/#{arities_str}")

    for arity <- arities do
      # the value of option :arg_pos is at this point a function which defines
      # the argument (position) which should be branched. anonymous functions
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
            unquote(Macro.escape(patterns)),
						unquote(Macro.escape(match_binding)),
            unquote(Macro.escape(transformer)),
            unquote(module),
            unquote(fun),
            unquote(args),
            unquote(opts)
          )
        end
      end
    end
  end

  def build_default(module, fun, args) do
    quote do
      unquote(module).unquote(fun)(unquote_splicing(args))
    end
  end

  def build_case(patterns, match_binding, {m, f, a} = _transformer, module, fun, args, opts) do

    branched_arg_pos = Keyword.get(opts, :arg_pos)
    branched_arg = Enum.at(args, branched_arg_pos)

    clauses =
      for pattern <- patterns do
        recomposed_arg = apply(m, f, [pattern, branched_arg | a])
        recomposed_args = List.replace_at(args, branched_arg_pos, recomposed_arg)

        quote do
          unquote(pattern) ->
            unquote(module).unquote(fun)(unquote_splicing(recomposed_args))
        end
      end
      |> List.flatten()

    if clauses == [] do
      Logger.critical("Failed to create branches for #{inspect(args)}")
      []
    else
      quote do
        case unquote(match_binding) do
          unquote(clauses)
        end
      end
    end
  end
end
