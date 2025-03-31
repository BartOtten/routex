defmodule Routex.Extension.RuntimeCallbacks do
  @moduledoc """
  Call functions at runtime by providing them in the configuration. Can be used to set the state for packages such as:

  - Gettext
  - Fluent
  - Cldr

   ## Options
    - `runtime_callbacks` - list of {m,f,a} tuples. An argument being a list starting with `:attrs` is transformed to a call `get_in(attrs(), rest)`

    ## Example configuration
    ```diff
    # file lib/example_web/routex_backend.ex
    defmodule ExampleWeb.RoutexBackend do
      use Routex.Backend,
      extensions: [
        Routex.Extension.Attrs,
    +   Routex.Extension.RuntimeCallbacks,
    ],
    + runtime_callbacks: [{Gettext, :put_locale, [[:attrs, :language]]},{Cldr, :put_locale, [ExampleCldr, [:attrs, :locale]]}],
    ```

    ## `Routex.Attrs`
    **Requires**
    - none

    **Sets**
    - none

    ## Helpers
    runtime_callbacks(attrs :: T.attrs) :: :ok
  """
  @behaviour Routex.Extension

  alias Routex.Types, as: T

  @impl Routex.Extension
  def configure(opts, _backend) do
    Enum.each(opts[:runtime_callbacks], fn {m, f, a} ->
      arity = length(a)
      ensure_provided!(m, f, arity)
    end)

    opts
  end

  @impl Routex.Extension
  @spec create_helpers(T.routes(), T.backend(), T.env()) :: T.ast()
  def create_helpers(_routes, backend, _env) do
    ast = build_ast(backend)

    quote do
      def runtime_callbacks(attrs) do
        (unquote_splicing(ast))
        :ok
      end
    end
  end

  @doc """
  A plug fetching the attributes from the connection and calling helper function `runtime_callbacks/1`
  """
  def plug(conn, _opts, attrs) do
    rt_attrs = conn |> Routex.Attrs.get()
    attrs.__helper_mod__.runtime_callbacks(rt_attrs)
    conn
  end

  @doc """
  A Phoenix Lifecycle Hook fetching the attributes from the socket and calling helper function `runtime_callbacks/1`
  """
  def handle_params(_params, _session, socket, attrs) do
    rt_attrs = socket |> Routex.Attrs.get()
    attrs.__helper_mod__.runtime_callbacks(rt_attrs)
    {:cont, socket}
  end

  defp build_ast(backend) do
    config = backend.config() |> Map.from_struct()

    for {m, f, a} <- config[:runtime_callbacks] || [] do
      a = Enum.map(a, &map_argument/1)
      build_callback_ast(m, f, a)
    end
  end

  defp build_callback_ast(m, f, a) do
    quote do: unquote(m).unquote(f)(unquote_splicing(a))
  end

  defp map_argument([:attrs | rest]) do
    quote do
      get_in(attrs, unquote(rest))
    end
  end

  defp map_argument(arg), do: arg

  defp ensure_provided!(package, fun, arity) do
    Code.ensure_loaded!(package)

    function_exported?(package, fun, arity) ||
      raise "#{package} does not provide #{fun}/#{arity}. Please check the value of `:runtimer_callbacks` in the Routex backend module"
  end
end
