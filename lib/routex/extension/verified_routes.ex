defmodule Routex.Extension.VerifiedRoutes do
  # credo:disable-for-this-file Credo.Check.Refactor.IoPuts
  @moduledoc ~S"""
  Supports the use of original route paths in controllers and templates while rendering
  transformed route paths at runtime without performance impact.

  > #### Implementation summary {:.info}
  > Each sigil and function eventualy delegates to the official
  > `Phoenix.VerifiedRoutes`.  If a non-branching route is provided it will
  > simply delegate to the official Phoenix function. If a branching route is
  > provided, it will use a branching mechanism before delegating.

  #### Alternative Verified Route sigil
  Provides a sigil (default: `~l`) to verify transformed and/or branching routes.
  The sigil to use can be set to `~p` to override the default of Phoenix as
  it is a drop-in replacement. If you choose to override the default Phoenix sigil,
  it is renamed (default: `~o`) and can be used when unaltered behavior is required.

  #### Variants of url/{2,3,4} and path/{2,3}
  Provides branching variants of (and delegates to) macro's provided by
  `Phoenix.VerifiedRoutes`. Both new macro's detect whether branching should be
  applied.

  ## Options
  - `verified_sigil_routex`: Sigil to use for Routex verified routes (default `"~l"`)
  - `verified_sigil_phoenix`: Replacement for the native (original) sigil when `verified_sigil_routex`
    is set to "~p". (default: `"~o"`)
   - `verified_url_routex`: Function name to use for Routex verified routes powered `url`. (default: `:rtx_url`)
  - `verified_url_phoenix`: Replacement for the native `url` function when `verified_url_routex`
    is set to `:url`. (default: `:phx_url`)
   - `verified_path_routex`: Function name to use for Routex verified routes powered `path` (default `:rtx_path`)
  - `verified_path_phoenix`: Replacement for the native `path` function  when `verified_path_routex`
    is set to `:path`. (default: `:phx_path`)

  When `verified_sigil_routex` is set to "~p" an additional change must be made.

  ```diff
  # file /lib/example_web.ex
  defp routex_helpers do
  +  import Phoenix.VerifiedRoutes,
  +      except: [sigil_p: 2, url: 1, url: 2, url: 3, path: 2, path: 3]

      import unquote(__MODULE__).Router.RoutexHelpers, only: :macros
      alias unquote(__MODULE__).Router.RoutexHelpers, as: Routes
  end
  ```

  ## Configuration
  ```diff
  # file /lib/example_web/routex_backend.ex
  defmodule ExampleWeb.RoutexBackend do
    use Routex.Backend,
    extensions: [
      Routex.Extension.AttrGetters, # required
      Routex.Extension.Alternatives,
      [...]
  +   Routex.Extension.VerifiedRoutes
  ],
  + verified_sigil_routex: "~p",
  + verified_sigil_phoenix: "~o",
  + verified_url_routex: :url,
  + verified_url_phoenix: :url_native,
  + verified_path_routex: :path,
  + verified_path_phoenix: :path_native,
  ```

  ## Pseudo result
  ```elixir
  # given Routex behavior is assigned ~l
  # given the default behavior is assigned ~o
  # given the official macro of Phoenix is assigned ~p

  # given another extension has transformed the route
  ~o"/products/#{product}"   ⇒  ~p"/products/#{products}"
  ~l"/products/#{product}"   ⇒  ~p"/transformed/products/#{product}"

  # given another extension has generated branches / alternative routes
  ~o"/products/#{product}"  ⇒  ~p"/products/#{products}"
  ~l"/products/#{product}"  ⇒
          case current_branch do
            nil     ⇒  ~p"/products/#{product}"
            "en"    ⇒  ~p"/products/en/#{product}"
            "eu_nl" ⇒  ~p"/europe/nl/products/#{product}"
            "eu_be" ⇒  ~p"/europe/be/products/#{product}"
          end
  ```

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none
  """
  @behaviour Routex.Extension

  import Routex.Branching

  alias Routex.Matchable

  require Logger
  require Phoenix.VerifiedRoutes
  require Routex.Branching

  @cell_width 20
  @defaults %{
    verified_sigil: %{phoenix: "~p", routex: "~l", default_replacement: "~o"},
    verified_url: %{phoenix: :url, routex: :url_rtx, default_replacement: :url_phx},
    verified_path: %{phoenix: :path, routex: :path_rtx, default_replacement: :path_phx}
  }

  @impl Routex.Extension
  def configure(config, backend) do
    final_config_map = merge_defaults_and_config(@defaults, config)
    print_message(final_config_map, backend)

    opts_list =
      Enum.flat_map(final_config_map, fn {config_prefix, %{routex: routex, native: native}} ->
        [
          {concat_atoms(config_prefix, :routex), routex},
          {concat_atoms(config_prefix, :phoenix), native}
        ]
      end)

    config ++ opts_list
  end

  @impl Routex.Extension
  def create_helpers(routes, backend, _env) do
    # print a newline so the branch_macro's can safely print in their own
    # empty space
    IO.puts("")

    config = backend.config()
    match_ast = quote do: Routex.Utils.get_helper_ast(__CALLER__)
    to_macro_name = fn "~" <> letter -> String.to_atom("sigil_" <> letter) end

    macros_ast = [
      branch_macro(
        routes,
        match_ast,
        Phoenix.VerifiedRoutes,
        :sigil_p,
        as: config |> get_value(:verified_sigil, :routex) |> then(&to_macro_name.(&1)),
        orig: config |> get_value(:verified_sigil, :phoenix) |> then(&to_macro_name.(&1)),
        arg_pos: fn arity -> arity - 1 end,
        clause_transformer: {__MODULE__.Transformers, :clause_transformer, []},
        argument_transformer: {__MODULE__.Transformers, :argument_transformer, []}
      ),
      branch_macro(
        routes,
        match_ast,
        Phoenix.VerifiedRoutes,
        :url,
        as: config |> get_value(:verified_url, :routex),
        orig: config |> get_value(:verified_url, :phoenix),
        arg_pos: fn arity -> arity end,
        clause_transformer: {__MODULE__.Transformers, :clause_transformer, []},
        argument_transformer: {__MODULE__.Transformers, :argument_transformer, []}
      ),
      branch_macro(
        routes,
        match_ast,
        Phoenix.VerifiedRoutes,
        :path,
        as: config |> get_value(:verified_path, :routex),
        orig: config |> get_value(:verified_path, :phoenix),
        arg_pos: fn arity -> arity end,
        clause_transformer: {__MODULE__.Transformers, :clause_transformer, []},
        argument_transformer: {__MODULE__.Transformers, :argument_transformer, []}
      )
    ]

    macros_ast
  end

  defp print_message(config, config_module) do
    warning_msg =
      if Enum.any?(config, fn {_, mapping} -> mapping.phoenix == mapping.routex end),
        do: [
          """
          \nDue to the configuration in module `#{inspect(config_module)}` one or multiple
          Routex variants use the default name of their native Phoenix equivalents. The native
          macro's, sigils or functions have been renamed.
          """
        ]

    macro_names_table = table(config)

    IO.puts("")

    Routex.Utils.print([
      """
      \n-- Notice --
      Routex extension VerifiedRoutes generates variants of the
      official Phoenix VerifiedRoutes macro's. While the Native macro's
      directly delegate to the official Phoenix macro's, the Routex variants
      apply route transfomations and/or automated branching before delegation.
      """,
      warning_msg,
      macro_names_table,
      """
      Documentation: https://hexdocs.pm/routex/extensions/verified_routes.html
      """
    ])
  end

  defp merge_defaults_and_config(defaults, config) do
    for {config_prefix, _defaults} <- defaults do
      phoenix = get_value(config, config_prefix, :phoenix)
      routex = get_value(config, config_prefix, :routex)
      replacement = get_value(config, config_prefix, :default_replacement)

      if routex == phoenix do
        {config_prefix, %{phoenix: phoenix, routex: routex, native: replacement}}
      else
        {config_prefix, %{phoenix: phoenix, routex: routex, native: phoenix}}
      end
    end
  end

  defp get_value(config, prefix, key) when is_list(config) do
    Keyword.get(config, concat_atoms(prefix, key), @defaults[prefix][key])
  end

  defp get_value(config, prefix, key) when is_map(config) do
    Map.get(config, concat_atoms(prefix, key), @defaults[prefix][key])
  end

  defp concat_atoms(a1, a2) do
    :"#{a1}_#{a2}"
  end

  defp table(config) do
    heading = row(["Native", "Routex"])
    divider = row([String.duplicate("-", @cell_width * 2 + 1)])

    body =
      for {_config_key, %{phoenix: _phoenix, routex: routex, native: native}} <- config do
        [native, routex] |> row()
      end

    ["\n", heading, divider, body, "\n"]
  end

  defp row(items) do
    # credo:disable-for-next-line
    items |> Enum.map(&cell/1) |> Enum.intersperse("|") |> then(&(&1 ++ ["\n"]))
  end

  defp cell(content, width \\ @cell_width) do
    [" ", content |> to_string() |> String.pad_trailing(width)]
  end

  defmodule Transformers do
    @moduledoc false
    def clause_transformer(route, {:sigil_p, _meta, [{:<<>>, _meta2, _segments} = ast, []]}),
      do: clause_transformer(route, ast)

    def clause_transformer(route, {:<<>>, _meta, segments}),
      do: clause_segments_transformer(route, segments)

    def clause_segments_transformer(route, segments) do
      orig_record = route |> Routex.Attrs.get!(:__origin__) |> Matchable.new()
      arg_record = segments |> Matchable.new()

      if Matchable.match?(orig_record, arg_record) do
        route |> Routex.Attrs.get!(:__branch__) |> List.last()
      else
        :skip
      end
    end

    def argument_transformer(
          pattern,
          {:sigil_p, meta, [{:<<>>, _meta, _segments} = path_ast, opts]}
        ) do
      new_path_ast = {:<<>>, _meta, _segments} = argument_transformer(pattern, path_ast)
      {:sigil_p, meta, [new_path_ast, opts]}
    end

    def argument_transformer(pattern, {:<<>>, meta, segments}) do
      new_segments = argument_segments_transformer(pattern, segments)
      {:<<>>, meta, new_segments}
    end

    def argument_segments_transformer(pattern, segments) do
      orig_record = pattern |> Routex.Attrs.get!(:__origin__) |> Matchable.new()
      orig_pattern = orig_record |> Matchable.to_pattern()
      new_pattern = pattern |> Matchable.new() |> Matchable.to_pattern()
      arg_record = segments |> Matchable.new()

      if Matchable.match?(orig_record, arg_record) do
        ast =
          quote do
            unquote(orig_pattern) = unquote(Macro.escape(arg_record))
            unquote(new_pattern)
          end

        {new_segments, _bindings} = Code.eval_quoted(ast)
        Matchable.to_ast_segments(new_segments)
      else
        :skip
      end
    end
  end
end
