defmodule Routex.Extension.RuntimeCallbacks do
  @moduledoc """
  The RuntimeCallbacks extension enable to configure callback functions
  -triggered by the Plug pipeline and LiveViews handle_params- by providing a
  list of `{module, function, arguments}` tuples. This is particularly useful
  for integrating with internationalization libraries like:

  * Gettext - Set language for translations
  * Fluent - Set language for translations
  * Cldr - Set locale for the Cldr suite

  > #### In combination with... {: .neutral}
  > This extension calls other functions with values from `Routex.Attrs` during
  > runtime. These attributes can be set by other extensions such as
  > `Routex.Extension.Alternatives` (compile time),
  > `Routex.Extension.Localize` (compile time and runtime),
  > `Routex.Extension.Localize.Routes` (compile time)
  > and `Routex.Extension.Localize.Runtime` (run time)


  ### Options

  * `runtime_callbacks` - List of `{module, function, arguments}` tuples. Any argument
    being a list starting with `:attrs` is transformed into `get_in(attrs(), rest)`.

  ### Example Configuration

  ````diff
  defmodule MyApp.RoutexBackend do
  use Routex.Backend,
    extensions: [
      Routex.Extension.Attrs,
  +   Routex.Extension.RuntimeCallbacks
    ],
    runtime_callbacks: [
  +   # Set Gettext locale from :language attribute
  +   {Gettext, :put_locale, [[:attrs, :language]]},

  +   # Set CLDR locale from :locale attribute
  +   {Cldr, :put_locale, [MyApp.Cldr, [:attrs, :locale]]}
    ]
  end
  ````

  ## Error Handling

  The extension validates all callbacks during compilation to ensure the specified modules and functions exist:

  * Checks if the module is loaded
  * Verifies the function exists with correct arity
  * Raises a compile-time error if validation fails

  Example error:

  ````elixir
  ** (RuntimeError) Gettext does not provide set_locale/1.
   Please check the value of :runtime_callbacks in the Routex backend module
  ````

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
