defmodule Routex.Extension.VerifiedRoutes do
  @moduledoc ~S"""
  Provides support for branching routes with compile-time verification. This
  allows the use of the original route paths in controllers and templates.

  > #### Implementation summary {:.info}
  > Each sigil and function eventualy delegates to the official
  > `Phoenix.VerifiedRoutes`.  If a non-branching route is provided it will
  > simply delegate to the official Phoenix function. If a branching route is
  > provided, it will use a branching mechanism before delegation.

  ## Alternative Verified Route sigil
  Provides a sigil (default: ~l) to verify branching routes. The sigil to use
  can be set to ~p to override the default of Phoenix as it is a drop-in
  replacement. If you choose to override the default Phoenix sigil, this
  original sigil is renamed (default: ~o).

  ## Variants of url/{2,3,4} and path/{2,3}
  Provides branching variants of (and delegates to) functions provided by
  `Phoenix.VerifiedRoutes`. Both functions detect whether branching should be
  applied.

  ## Options
  - `verified_sigil_routex`: Sigil to use for Routex verified routes (default "~l")
  - `verified_sigil_original`: Sigil for original routes when `verified_sigil_routex`
    is set to "~p". (default: "~o")

  When `verified_sigil_routex` is set to "~p" an additional change must be made.

  ```diff
  # file /lib/example_web.ex
  defp routex_helpers do
  + import Phoenix.VerifiedRoutes, only: :functions
    import ExampleWeb.Router.Routex
  end
  ```

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex,
    extensions: [
  +   Routex.Extension.VerifiedRoutes,
  ],
  + verified_sigil_routex: "~p",
  + verified_sigil_original: "~o",
  ```

  ## Pseudo result (simplified)
      # given Routex is configured to use ~l
      # given Phoenix is assigned ~o (for example clarity)

      # given other extensions has provided transformations
      ~o"/products/#{product}"   ⇒  ~p"/products/#{products}"
      ~l"/products/#{product}"   ⇒  ~p"/transformed/products/#{product}"

      # given another extension has generated branches / alternative routes
      ~o"/products/#{product}"  ⇒  ~p"/products/#{products}"

      ~l"/products/#{product}"  ⇒
              case branch do
                nil ⇒  ~p"/products/#{product}"
                "en" ⇒  ~p"/products/en/#{product}"
                "eu_nl" ⇒  ~p"/europe/nl/products/#{product}"
                "eu_be" ⇒  ~p"/europe/be/products/#{product}"
              end

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none
  """

  # alias Routex.Attrs
  # alias Routex.Utils
  # alias Routex.Path
  # alias Routex.Route

  require Phoenix.VerifiedRoutes
  require Logger
  require Routex.Branching
  import Routex.Branching
  import Routex.Match

  @behaviour Routex.Extension
  @phoenix_sigil "~p"
  @default_verified_sigil_routex "~l"
  @default_verified_sigil_original "~o"

  @impl Routex.Extension
  def configure(config, cm) do
    routex = Keyword.get(config, :verified_sigil_routex, @default_verified_sigil_routex)
    original = Keyword.get(config, :verified_sigil_original, @default_verified_sigil_original)

    p1 =
      if routex == @phoenix_sigil do
        "\nThe default sigil used by Phoenix Verified Routes is overridden by Routex due to the configuration in `#{inspect(cm)}`.

      #{routex}: localizes and verifies routes. (override)
      #{original}: only verifies routes. (original)"
      else
        "\nRoutes can be localized using the #{routex} sigil"
      end

    p2 = "\n\nDocumentation: https://hexdocs.pm/routex/extensions/verified_routes.html\n"

    Routex.Utils.print([p1, p2])

    Keyword.merge(config, verified_sigil_routex: routex, verified_sigil_original: original)
  end

  require Phoenix.VerifiedRoutes

  @impl true
  def create_helpers(routes, _cm, _env) do

    # print a newline so the branch_macro's can safely print in their own
    # empty space
   #  IO.puts("")

	recompose_ast = []
	# recompose_ast = for route <- routes do
	# 	for alt <- Routex.Attrs.get!(route, :alternatives) do
  #    alt_pattern = Routex.Match.to_pattern(alt)
  #    alt_order = Routex.Attrs.get!(alt, :__order__) |> List.last()

	# 		Routex.Match.to_func(route, :recompose, [var: alt_order], quote do



																																	
  #  pat = unquote(alt_pattern)
	# {:<<>>, [], unquote(elem(pat,3)}
	# 	end)
			
  #   end |> Routex.Dev.inspect_ast()
	# end

		
     match_ast = quote do: Routex.Utils.get_helper_ast(__CALLER__)

	
	macros_ast  = [
      branch_macro(
        routes,
        match_ast,
        {__MODULE__.PreCompiled, :clause_transformer, []},
				 {__MODULE__.PreCompiled, :argument_transformer, []},
        Phoenix.VerifiedRoutes,
        :sigil_p,
        as: :sigil_p,
        orig: :sigil_o,
        arg_pos: fn arity -> arity - 1 end
      ),
      branch_macro(
        routes,
        match_ast,
        {__MODULE__.PreCompiled, :clause_transformer, []},
				 {__MODULE__.PreCompiled, :argument_transformer, []},
        Phoenix.VerifiedRoutes,
        :url,
        as: :url,
        orig: :url_o,
        arg_pos: fn arity -> arity - 1 end
      ),
      branch_macro(
        routes,
        match_ast,
        {__MODULE__.PreCompiled, :clause_transformer, []},
				 {__MODULE__.PreCompiled, :argument_transformer, []},
        Phoenix.VerifiedRoutes,
        :path,
        as: :path,
        orig: :path_o,
        arg_pos: fn arity -> arity - 1 end
      )
    ]

		recompose_ast ++ macros_ast
  
	end
	end

defmodule Routex.Extension.VerifiedRoutes.PreCompiled do
	require Routex.Match
	import Routex.Match

	def clause_transformer(route, branched_arg), do: Routex.Attrs.get!(route, :__order__) |> List.last()
	
  # def argument_transformer(route, branched_arg) do

	
	def argument_transformer(pattern, branched_arg) do
		IO.inspect(branched_arg, label: :BRANCHED_ARG)
		
orig_pattern = pattern |> Routex.Attrs.get!(:__origin__) |> Routex.Match.new()
    new_pattern = pattern |> Routex.Match.new()
    segments_pattern = branched_arg |> Routex.Match.new()

    dyn_map =
      orig_pattern
      |> elem(2)
      |> Enum.with_index()
      |> Enum.reduce([], fn
        {":" <> _ = segment, idx}, acc ->
          [{segment, elem(segments_pattern, 2) |> Enum.at(idx)} | acc]

        _, acc ->
          acc
      end)
      |> Map.new()

    new_segments =
      new_pattern
      |> elem(2)
      |> Enum.reduce([], fn
        segment, [] = _acc -> ["/" <> segment | []]
        ":" <> _ = segment, [h | t] -> [dyn_map[segment], h <> "/" | t]
        segment, [h | t] when is_binary(segment) and is_binary(h) -> [h <> "/" <> segment | t]
        segment, acc when is_binary(segment) -> ["/" <> segment | acc]
        segment, acc -> [segment | acc]
      end)
      |> List.flatten()

    new_segments =
      case new_segments do
        [] -> ["/"]
        other -> other |> Enum.reject(&is_nil/1) |> Enum.reverse()
      end

    q = match(segments_pattern, :query)
    f = match(segments_pattern, :fragment)


# hack to support "/users/login?_action=updated
		new_segments =
			case q do
				nil -> new_segments
				[h|t] when is_binary(h) -> new_segments ++ ["?" <> h | t] |> List.flatten()
				q -> new_segments ++ ["?" | q] |> List.flatten()
			end


    new_segments = (f && (new_segments ++ ["#", f]) |> List.flatten()) || new_segments

    new_segments = List.wrap(new_segments)

    case branched_arg do
      {:sigil_p, _meta, _args} ->
        {:sigil_p, [], [{:<<>>, [], new_segments}, []]}

      _ ->
        {:<<>>, [], new_segments}
    end |> IO.inspect(label: :RECOMPOSED)
  end
	end

