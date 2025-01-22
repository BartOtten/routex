defmodule Routex.Backend do
  @moduledoc """
  > #### `use Routex.Backend` {: .info}
  > When use'd this module generates a Routex backend module and
  > a configuration struct using the `configure/2` callbacks of
  > the extensions provided in `opts`.
  >
  > See also: [Routex Extensions](EXTENSIONS.md).

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

  alias Routex.Processing

  @typedoc """
    A Routex backend module
  """
  @type t :: module

  @spec __using__(opts :: list) :: Macro.output()
  defmacro __using__(opts) do
    opts = execute_config_callbacks(opts, __CALLER__)
    extensions = Keyword.get(opts, :extensions, [])

    quote do
      defstruct unquote(Macro.escape(opts))

      @typedoc """
        A Routex backend struct
      """
      @type config :: struct()

      @spec config :: config
      def config, do: %__MODULE__{}

      @spec extensions :: [module]
      def extensions, do: unquote(Macro.escape(extensions))
    end
  end

  defp execute_config_callbacks(opts, env) do
    {opts, _binding} = Code.eval_quoted(opts, [], env)

    reduced_opts =
      for extension <- opts[:extensions], extension != [], reduce: opts do
        acc ->
          ext_mod = Macro.expand_once(extension, env)
          conf_mod = env.module

          Processing.exec_when_defined(conf_mod, ext_mod, :configure, acc, [acc, conf_mod])
      end

    Keyword.new(reduced_opts)
  end
end
