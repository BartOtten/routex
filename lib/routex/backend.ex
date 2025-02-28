defmodule Routex.Backend do
  @moduledoc """
  > #### `use Routex.Backend` {: .info}
  > When use'd this module generates a Routex backend module and
  > a configuration struct using the `configure/2` callbacks of
  > the extensions provided in `opts`.
  >
  > See also: [Routex Extensions](EXTENSION_DEVELOPMENT.md).

  **Example**

       iex> defmodule MyApp.RtxBackend do
       ...>  use Routex.Backend,
       ...>   extensions: [
       ...>    Routex.Extension.VerifiedRoutes,
       ...>    Routex.Extension.AttrGetters,
       ...>   ],
       ...>   extension_x_config: [key: "value"]
       ...> end
       iex> IO.inspect(%MyApp.RtxBackend{})
       %MyApp.RtxBackend{
         extension_x_config: [key: "value"],
         extensions: [Routex.Extension.VerifiedRoutes, Routex.Extension.AttrGetters],
         verified_sigil_routex: "~l",
         verified_sigil_original: "~o"
       }

  Values in the configuration can be overridden by providing an override map to the `:private` option of a scope or route.

  **Example**

      live /products, MyApp.Web.ProductIndexLive, :index, private: %{rtx: %{overridden_key: value}}
  """

  @typedoc """
    A Routex backend module
  """

  alias Routex.Utils

  @type t :: module

  @default_reduction_limit 10
  @default_callbacks Routex.Extension.behaviour_info(:callbacks)

  @spec __using__(opts :: list) :: Macro.output()
  defmacro __using__(opts) do
    # eval_quoted is inside a macro is considered bad practice as it will attempt
    # to evaluate runtime values at compile time. However, that is exactly what
    # we want to happen this time.
    {new_opts, extensions_per_callback} =
      opts
      |> eval_opts(__CALLER__)
      |> Keyword.put(:__backend__, __CALLER__.module)
      |> Keyword.put(:__processed__, [])
      |> prepare_unquoted()

    extensions =
      extensions_per_callback
      |> Map.values()
      |> List.flatten()
      |> Enum.uniq()

    kw_opts = Keyword.new(new_opts)

    quote do
      defstruct unquote(Macro.escape(kw_opts))

      @typedoc """
        A Routex backend struct
      """
      @type config :: struct()

      @spec config :: config
      @doc "Returns a compiled Routex Backend configuration"
      def config, do: %__MODULE__{}

      @spec extensions :: [module]
      @doc "Returns the list of extensions used in this backend."
      def extensions, do: unquote(Macro.escape(extensions))

      @spec callbacks :: %{module() => list()}
      @doc "Returns a map with extensions per callback."
      def callbacks, do: unquote(Macro.escape(extensions_per_callback))
    end
  end

  defp prepare_unquoted(opts, reduction \\ 1) do
    backend = Keyword.get(opts, :__backend__)
    enforce_reduction_limit!(reduction, backend)

    extensions = Keyword.get(opts, :extensions, [])
    Enum.each(extensions, &ensure_availability!/1)
    extensions_per_callback = map_extensions_per_callback(extensions)
    new_opts = apply_callback_per_extension(extensions_per_callback[:configure], :configure, opts)
    new_extensions = Keyword.get(new_opts, :extensions, [])

    if new_extensions == extensions do
      new_extensions_per_callback = map_extensions_per_callback(extensions)
      {new_opts, new_extensions_per_callback}
    else
      prepare_unquoted(new_opts, reduction + 1)
    end
  end

  defp map_extensions_per_callback(extensions, callbacks \\ @default_callbacks) do
    callbacks
    |> Enum.map(fn {callback, arity} ->
      provided_by = Enum.filter(extensions, &function_exported?(&1, callback, arity))
      {callback, provided_by}
    end)
    |> Enum.into(%{})
  end

  defp apply_callback_per_extension(extensions, callback, opts) do
    Enum.reduce(extensions, opts, fn ext, acc ->
      print? = Enum.member?(opts[:__processed__], {callback, ext})
      new_opts = capture_io(fn -> ext.configure(acc, opts[:__backend__]) end, print?)
      Keyword.update(new_opts, :__processed__, [], &[{callback, ext} | &1])
    end)
  end

  defp eval_opts(opts, caller) do
    # eval_quoted is inside a macro is considered bad practice as it will attempt
    # to evaluate runtime values at compile time. However, that is exactly what
    # we want to happen this time.
    {opts, _binding} = Code.eval_quoted(opts, [], caller)
    opts
  end

  defp capture_io(fun, false), do: fun.()

  defp capture_io(fun, true) do
    {:group_leader, original_gl} = Process.info(self(), :group_leader)
    {:ok, capture_gl} = StringIO.open("")

    try do
      Process.group_leader(self(), capture_gl)
      fun.()
    after
      Process.group_leader(self(), original_gl)
    end
  end

  defp enforce_reduction_limit!(reductions, limit \\ @default_reduction_limit, backend) do
    if reductions > limit do
      Utils.alert("Reduction limit exceeded", "#{limit} reductions")

      Utils.print(
        __MODULE__,
        """
        This issue appears to be caused by an extension defined
        in #{backend} that is repeatedly appending new
        entries to the extension list.
        """
      )

      raise "#{backend}: Reduction limit exceeded: #{limit} reductions"
    end
  end

  defp ensure_availability!(extension) do
    if not Code.ensure_loaded?(extension) do
      Routex.Utils.alert("Extension #{inspect(extension)} is missing")

      raise CompileError
    end
  end
end
