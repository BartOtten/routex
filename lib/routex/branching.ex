defmodule Routex.Branching do
  alias Routex.Utils

  require Logger

  @doc """
  Takes a list of match patterns and creates the AST for branching variants
  for all arities of `function` in `module`.


  ** Args
  - match_binding: the argument for the case clause
  - patterns: the match patterns of the case clause
  - transformer: transforms the original arguments value

  ** Example

  We want to create a branching variant of the `url` macro in `Phoenix,.VerifiedRoutes` module. The original
  macro generates code that simply prints the given path argument, but we want to it to write multiple clauses and
  prefix the given argument based on the clause.

    defmacro url(path, opts \\ []) do -> quote do IO.puts(path) end

  Given this code:

   patterns = ["en", "nl"]
  match_binding = var!(external_var)
  arg_transformer = fn pattern, arg -> "europe/" <> pattern <> "/" <> arg end

    branch_macro(patterns, match_binding, arg_transformer, Phoenix.VerifiedRoutes, :url,
  	as: :url,
  	orig: :url_original,
  	arg_pos: fn arity -> arity - 1 end
  )

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
        pattern_transformer,
        transformer,
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
    arities = :macros |> module.__info__() |> Keyword.get_values(fun)
    patterns = Enum.map(patterns, &Macro.escape/1)

    ## Print a message to make developers aware of branched macro's.
    arities_str =
      if length(arities) == 1,
        do: "#{hd(arities)}",
        else: "{#{Enum.join(arities, ",")}}"

    mod_name = module |> Module.split() |> Enum.join(".")
    Utils.print("Generate branching variant of: #{mod_name}.#{fun}/#{arities_str}")

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
          template_path_segments = case unquote(args) |> List.first() do
						{:<<>>, _, segments} -> segments |> Routex.Path.split()
						{_other, _, [{:<<>>, _, segments}, []]} -> segments |> Routex.Path.split()
						other -> raise other
					end


          template_path_match_record = template_path_segments |> Routex.Match.new()
					# Routex.Path.to_match_pattern() |> Enum.split_while(fn
					# 	"?" <> _ -> false
					# 	"?" -> false
					# 	x -> true
					# end) |> dbg()

          matching_route =
            Enum.find(unquote(patterns), fn route ->
              Routex.Match.match?(route.path |> Routex.Match.new(), template_path_match_record)
            end)

           #IO.puts("Template #{inspect(__CALLER__.module)} includes #{inspect(template_path_segments)}\n Match: #{inspect(template_path_match_record)} => #{inspect(matching_route, pretty: true)}")

          alternatives =
						cond do
							matching_route == nil -> []
						  matching_route |> Routex.Attrs.get!(:__order__) |> List.last() != 0 -> [] # non-root routes are not branched
						  alternatives = Routex.Attrs.get!(matching_route, :alternatives) -> alternatives
						end

          match_binding = Routex.Utils.get_helper_ast(__CALLER__)

          Routex.Branching.build_case(
            alternatives,
            match_binding,
            unquote(Macro.escape(pattern_transformer)),
            unquote(Macro.escape(transformer)),
            unquote(module),
            unquote(fun),
            unquote(args),
            unquote(opts)
          )
         # |> Routex.Dev.inspect_ast()
        end
      end
    end
  end

  def build_default(module, fun, args) do
    quote do
      unquote(module).unquote(fun)(unquote_splicing(args))
    end
  end

  def build_case(
        patterns,
        match_binding,
        {cm, cf, ca} = _pattern_transformer,
        {m, f, a} = _transformer,
        module,
        fun,
        args,
        opts
      ) do
    branched_arg_pos = Keyword.get(opts, :arg_pos, 0)
    branched_arg = Enum.at(args, branched_arg_pos)

    clauses =
      for pattern <- patterns do
        recomposed_pattern = apply(cm, cf, [pattern | ca])
        recomposed_arg = apply(m, f, [pattern, branched_arg | a])
        recomposed_args = List.replace_at(args, branched_arg_pos, recomposed_arg)

        quote do
          unquote(recomposed_pattern) ->
            unquote(module).unquote(fun)(unquote_splicing(recomposed_args))
        end
      end
      |> List.flatten()
      |> Enum.uniq()

    if clauses == [] do
      Logger.critical("Failed to create branches for #{inspect(args)}")
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
