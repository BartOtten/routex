defmodule Routex.Extension.RuntimeDispatcher do
  @moduledoc """
  The `Routex.Extension.RuntimeDispatcher` enables the dynamic dispatching of
  functions to external libraries or modules during the Plug pipeline and
  LiveView's `handle_params`. This dispatching is configured using a list of
  `{module, function, arguments}` tuples and leverages attributes from
  `Routex.Attrs` at runtime.

  This is particularly useful for integrating with libraries that handle
  internationalization or localization, such as:

  * Gettext - Set language for translations
  * Fluent - Set language for translations
  * Cldr - Set locale for the Cldr suite

  > #### In combination with... {: .neutral}
  > This extension dispatches functions with values from `Routex.Attrs` during
  > runtime. These attributes are typically set by other extensions such as:
  >
  > * `Routex.Extension.Alternatives` (compile time)
  > * `Routex.Extension.Localize.Phoenix` (compile time and runtime)
  > * `Routex.Extension.Localize.Phoenix.Routes` (compile time)
  > * `Routex.Extension.Localize.Phoenix.Runtime` (runtime)

  ### Options

  * `dispatch_targets` - A list of `{module, function, arguments}` tuples. Any argument
    that is a list starting with `:attrs` is transformed into `get_in(attrs(), rest)`.

  ### Example Configuration

  ````elixir
  defmodule MyApp.RoutexBackend do
    use Routex.Backend,
      extensions: [
        Routex.Extension.Attrs,
        Routex.Extension.RuntimeDispatcher
      ],
      dispatch_targets: [
        # Dispatch Gettext locale from :language attribute
        {Gettext, :put_locale, [[:attrs, :language]]},

        # Dispatch CLDR locale from :locale attribute
        {Cldr, :put_locale, [MyApp.Cldr, [:attrs, :locale]]}
      ]
  end
  ````

  ## Error Handling

  The extension validates all dispatch configurations during compilation to
  ensure the specified modules and functions exist:

  * Checks if the module is loaded
  * Verifies the function exists with the correct arity
  * Raises a compile-time error if validation fails

  Example error:

  ````elixir
  ** (RuntimeError) Gettext does not provide put_locale/1.
   Please check the value of :dispatch_targets in the Routex backend module
  ````

  ## `Routex.Attrs`
  **Requires**
  - none

  **Sets**
  - none

  ## Helpers
  `dispatch_targets(attrs :: T.attrs) :: :ok`
  """

  @behaviour Routex.Extension

  alias Routex.Types, as: T

  @impl Routex.Extension
  def configure(opts, _backend) do
    Enum.each(opts[:dispatch_targets], fn {m, f, a} ->
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
      def dispatch_targets(attrs) do
        (unquote_splicing(ast))
        :ok
      end
    end
  end

  @doc """
  A plug fetching the attributes from the connection and calling helper function `dispatch_targets/1`
  """
  def call(conn, _opts) do
    attrs = conn |> Routex.Attrs.get()
    attrs.__helper_mod__.dispatch_targets(attrs)
    conn
  end

  @doc """
  A Phoenix Lifecycle Hook fetching the attributes from the socket and calling helper function `dispatch_targets/1`
  """
  def handle_params(_params, _session, socket) do
    attrs = Routex.Attrs.get(socket)
    attrs.__helper_mod__.dispatch_targets(attrs)
    {:cont, socket}
  end

  defp build_ast(backend) do
    config = backend.config() |> Map.from_struct()

    for {m, f, a} <- config[:dispatch_targets] || [] do
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
