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

  # defp uniform_path_matchspec(input) do
  #   Path.path_map(input)
  # end

  def routes() do
    [
      %Phoenix.Router.Route{
        path: "/products/:id",
        kind: :match,
        private: %{routex: %{__order__: [2, 0], __origin__: "/products/:id"}}
      },
      %Phoenix.Router.Route{
        path: "/alt1/:id/productsa/",
        kind: :match,
        private: %{routex: %{__order__: [2, 1], __origin__: "/products/:id"}}
      },
      %Phoenix.Router.Route{
        path: "/alt2/:id/productsb/",
        kind: :match,
        private: %{routex: %{__order__: [2, 2], __origin__: "/products/:id"}}
      }
    ]
  end

  @impl true
  def create_helpers(routes, _cm, env) do
    # print a newline so the branch_macro's can safely print in their own
    # empty space
    IO.puts("")

    match_ast = :fixMe # Routex.Utils.get_helper_ast(env)

    [
      branch_macro(
        routes,
        match_ast,
        {__MODULE__.PreCompiled, :clause_transformer, []},
        {__MODULE__.PreCompiled, :transformer, []},
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
        {__MODULE__.PreCompiled, :transformer, []},
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
        {__MODULE__.PreCompiled, :transformer, []},
        Phoenix.VerifiedRoutes,
        :path,
        as: :path,
        orig: :path_o,
        arg_pos: fn arity -> arity - 1 end
      )
    ]
		end
	end


defmodule Routex.Extension.VerifiedRoutes.PreCompiled do
 
  def clause_transformer(route) do
    # pattern =
     #  route |> Routex.Attrs.get!(:__origin__) |> Routex.Match.new() |> Routex.Match.to_pattern()

    order = route |> Routex.Attrs.get!(:__order__) |> List.last()

    order #, pattern}
  end

  def transformer(pattern, branched_arg) do

		IO.inspect(branched_arg, label: :BA)
		import Routex.Match
		orig_pattern = pattern |> Routex.Attrs.get!(:__origin__) |> Routex.Match.new()
		new_pattern = pattern |>  Routex.Match.new()
		segments_pattern = branched_arg |> Routex.Match.new()

		dyn_map =
			orig_pattern |> elem(2) |> Enum.with_index() |> Enum.reduce([], fn
	{":" <> _ = segment, idx}, acc -> [{segment, elem(segments_pattern, 2) |> Enum.at(idx)} | acc]
	_, acc -> acc
end) |> Map.new() 

		new_segments = new_pattern |> elem(2) |> Enum.map( fn
			":" <> _ = segment -> dyn_map[segment]
			segment when is_binary(segment) -> "/" <> segment
			segment -> segment
		end)

		new_segments = ["/" | new_segments] |> Enum.reject(&is_nil/1) |> Path.join() 

		q = match(segments_pattern, :query)
		f = match(segments_pattern, :fragment)

		new_segments =q && new_segments <> "?" <> q || new_segments
		new_segments =f && new_segments <> "#" <> f || new_segments

		new_segments = List.wrap(new_segments)


		case branched_arg do
			{:sigil_p,_meta, _args} -> 
	{:sigil_p, [delimiter: "\"", line: 34, column: 14],
 [
   {:<<>>, [line: 34, column: 14],
    new_segments},
   []
 ]}
				_ ->
				
    {:<<>>, [], new_segments} |> IO.inspect(label: :NEW_SEGS)
		#branched_arg |> IO.inspect(label: :BRANCHED_ARG)
end
	

		#branched_arg
  end
end
