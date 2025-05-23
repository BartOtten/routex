defmodule Routex.Backend do
  @moduledoc """
  > #### `use Routex.Backend`
  > When used, this module generates a Routex backend module and a configuration struct
  > by running the `configure/2` callbacks of the extensions provided in `opts`.
  >
  > See also: [Routex Extensions](EXTENSION_DEVELOPMENT.md).
  """

  alias Routex.Utils

  @typedoc "A Routex backend module"
  @type t :: module

  @default_reduction_limit 10
  @default_callbacks Routex.Extension.behaviour_info(:callbacks)

  @spec __using__(Keyword.t()) :: Macro.t()
  defmacro __using__(opts) do
    new_opts = prepare_unquoted(opts, __CALLER__)
    struct = struct_from_opts(new_opts)
    extensions_per_callback = group_extensions_per_callback(new_opts[:extensions])
    extensions = extract_extensions(extensions_per_callback)

    quote do
      @moduledoc """
      A backend module for Routex
      """

      unquote(struct)

      @typedoc "Routex Backend struct"
      @type config :: struct()

      @typedoc "List of extensions used in this backend"
      @type extensions :: [module]

      @typedoc "Map with extensions per callback."
      @type callbacks :: %{atom() => [module]}

      @doc "Returns a compiled Routex Backend configuration"
      @spec config :: config
      def config, do: %__MODULE__{}

      @doc "Returns the list of extensions used in this backend."
      @spec extensions :: extensions
      def extensions,
        do: unquote(Macro.escape(extensions))

      @doc "Returns a map with extensions per callback."
      @spec callbacks :: callbacks
      def callbacks, do: unquote(Macro.escape(extensions_per_callback))
    end
  end

  defp struct_from_opts(opts) do
    kw_opts = Keyword.new(opts)

    quote do
      defstruct unquote(Macro.escape(kw_opts))
    end
  end

  @doc false
  @spec prepare_unquoted(Keyword.t(), Macro.Env.t() | module) :: Keyword.t()
  def prepare_unquoted(opts, %Macro.Env{module: backend} = env) do
    opts = eval_opts(opts, env)
    prepare_unquoted(opts, backend)
  end

  def prepare_unquoted(opts, backend) do
    opts
    |> merge_private_opts(backend)
    |> process_extensions(backend)
  end

  defp merge_private_opts(opts, backend) do
    merge_opts(opts, __backend__: backend, __processed__: [], extensions: [])
  end

  defp merge_opts(a, b) do
    Keyword.merge(a, b, fn
      :extensions, a, b -> a ++ b
      _key, a, _b -> a
    end)
  end

  @doc false
  def process_extensions(opts, _backend) do
    extensions = opts[:extensions]
    ensure_extensions_loaded(extensions)

    extensions_per_callback = group_extensions_per_callback(extensions)

    Enum.reduce(extensions_per_callback[:configure], opts, fn ext, acc ->
      process_extension_callback(acc, :configure, ext)
    end)
  end

  defp ensure_extensions_loaded(extensions) do
    Enum.each(extensions, &ensure_availability!/1)
  end

  defp process_extension_callback(opts, callback, ext, reduction \\ 0) do
    processed? =
      opts
      |> Keyword.get(:__processed__, [])
      |> Enum.member?({callback, ext})

    new_opts =
      capture_io(
        fn ->
          ext.configure(opts, opts[:__backend__])
        end,
        processed?
      )

    new_extensions = new_opts[:extensions] -- opts[:extensions]

    if new_extensions != [] do
      enforce_reduction_limit!(reduction, opts[:__backend__], ext)
      ensure_extensions_loaded(new_extensions)

      Enum.reduce(new_extensions, new_opts, fn ext, acc ->
        process_extension_callback(acc, :configure, ext, reduction + 1)
      end)
    else
      update_processed(new_opts, callback, ext)
    end
  end

  defp update_processed(opts, callback, ext) do
    Keyword.update(opts, :__processed__, [{callback, ext}], fn list ->
      [{callback, ext} | list]
    end)
  end

  @doc false
  defp extract_extensions(extensions_per_callback) do
    extensions_per_callback
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
  end

  @doc false
  defp group_extensions_per_callback(extensions, callbacks \\ @default_callbacks) do
    callbacks
    |> Enum.map(fn {callback, arity} ->
      provided_by = Enum.filter(extensions, &function_exported?(&1, callback, arity))
      {callback, provided_by}
    end)
    |> Enum.into(%{})
  end

  defp eval_opts(opts, caller) do
    # Using Code.eval_quoted to force compile-time evaluation.
    {evaluated, _binding} = Code.eval_quoted(opts, [], caller)
    evaluated
  end

  # The capture_io helper: conditionally redirect output.
  defp capture_io(fun, false), do: fun.()

  defp capture_io(fun, true) do
    {:group_leader, original_gl} = Process.info(self(), :group_leader)

    try do
      {:ok, result} =
        StringIO.open("", fn pid ->
          Process.group_leader(self(), pid)
          fun.()
        end)

      result
    after
      Process.group_leader(self(), original_gl)
    end
  end

  defp enforce_reduction_limit!(reductions, backend, extension, limit \\ @default_reduction_limit) do
    if reductions > limit do
      Utils.alert("Reduction limit exceeded", "#{limit} reductions")

      Utils.print(
        __MODULE__,
        """
        This issue appears to be caused by #{extension} defined
        in #{backend} that is repeatedly appending new
        entries to the extension list.
        """
      )

      raise CompileError,
        description: "#{backend}: Reduction limit exceeded (max. #{limit} reductions)."
    end
  end

  defp ensure_availability!(extension) do
    if !Code.ensure_loaded?(extension) do
      description = "Extension #{inspect(extension)} not found."
      Utils.alert(description)
      raise CompileError, description: description
    end
  end
end
