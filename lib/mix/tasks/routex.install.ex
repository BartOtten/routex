# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

defmodule Mix.Tasks.Routex.Install.Docs do
  @moduledoc false

  def short_doc do
    "Install and configure Routex for use in an application."
  end

  def example do
    "mix routex.install"
  end

  def long_doc do
    """
    Install and configure Routex for use in an application.

    ## Example

    ```bash
    mix routex.install
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Routex.Install do
    @shortdoc __MODULE__.Docs.short_doc()

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Code.Common
    alias Igniter.Code.Function
    alias Igniter.Libs.Phoenix
    alias Igniter.Project
    alias Igniter.Util.Debug

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :routex,
        adds_deps: [{:routex, "~> 1.1"}],
        installs: [{:routex, "~> 1.1"}],
        example: __MODULE__.Docs.example()
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      web_module = Phoenix.web_module(igniter)
      dbg(igniter)

      igniter
      |> create_routex_backend(web_module)
      |> configure_web(web_module)
      |> configure_router(web_module)
    end

    defp configure_web(igniter, module) do
      Project.Module.find_and_update_module!(igniter, module, fn zipper ->
        with {:ok, zipper} <-
               Common.within(zipper, fn zipper ->
                 with {:ok, zipper} <- Common.move_to_do_block(zipper),
                      {:ok, zipper} <- Function.move_to_def(zipper, :router, 0),
                      {:ok, zipper} <- Common.move_to_do_block(zipper) do
                   line = "use Routex.Router"
                   {:ok, Common.add_code(zipper, line, placement: :before)}
                 end
               end),
             {:ok, zipper} <-
               Common.within(zipper, fn zipper ->
                 with {:ok, zipper} <- Common.move_to_do_block(zipper),
                      {:ok, zipper} <- Function.move_to_def(zipper, :controller, 0),
                      {:ok, zipper} <- Common.move_to_do_block(zipper) do
                   line = "unquote(routex_helpers())"
                   {:ok, Common.add_code(zipper, line, placement: :after)}
                 end
               end),
             {:ok, zipper} <-
               Common.within(zipper, fn zipper ->
                 with {:ok, zipper} <- Common.move_to_do_block(zipper),
                      {:ok, zipper} <- Function.move_to_def(zipper, :live_view, 0),
                      {:ok, zipper} <- Common.move_to_do_block(zipper) do
                   line = "on_mount(unquote(__MODULE__).Router.RoutexHelpers)"
                   {:ok, Common.add_code(zipper, line, placement: :after)}
                 end
               end),
             {:ok, zipper} <-
               Common.within(zipper, fn zipper ->
                 with {:ok, zipper} <- Common.move_to_do_block(zipper),
                      {:ok, zipper} <- Function.move_to_defp(zipper, :html_helpers, 0),
                      {:ok, zipper} <- Common.move_to_do_block(zipper) do
                   line = "unquote(routex_helpers())"
                   {:ok, Common.add_code(zipper, line, placement: :after)}
                 end
               end) do
          Common.within(zipper, fn zipper ->
            block = """
            defp routex_helpers do
             quote do
               import Phoenix.VerifiedRoutes,
                 except: [sigil_p: 2, url: 1, url: 2, url: 3, path: 2, path: 3]

               import unquote(__MODULE__).Router.RoutexHelpers, only: :macros
               alias unquote(__MODULE__).Router.RoutexHelpers, as: Routes
             end
            end
            """

            {:ok, Common.add_code(zipper, block, placement: :after)}
          end)
        end
      end)
    end

    defp configure_router(igniter, web_module) do
      module = Module.concat(web_module, "Router")

      Project.Module.find_and_update_module!(igniter, module, fn zipper ->
        with {:ok, zipper} <-
               Common.within(zipper, fn zipper ->
                 with {:ok, zipper} <- Common.move_to_do_block(zipper) do
                   line = "plug :routex"
                   {:ok, Common.add_code(zipper, line, placement: :after)}
                 end
               end) do
          Common.within(zipper, fn zipper ->
            with {:ok, zipper} <- Common.move_to_do_block(zipper),
                 {:ok, zipper} <- move_to_function(zipper, :scope) do
              module =
                web_module
                |> Module.split()
                |> List.insert_at(-1, "RoutexBackend")
                |> Enum.join(".")

              block = """
              preprocess_using #{module} do
                #{Debug.code_at_node(zipper)}
              end
              """

              {:ok, Common.replace_code(zipper, block)}
            end
          end)
        end
      end)
    end

    defp create_routex_backend(igniter, web_module) do
      module = Module.concat(web_module, "RoutexBackend")

      Project.Module.create_module(igniter, module, """
      use Routex.Backend,
      extensions: [Routex.Extension.AttrGetters]
      """)
    end

    defp move_to_function(zipper, function) do
      Common.move_to(zipper, fn zipper ->
        Function.function_call?(zipper, function)
      end)
    end
  end
else
  defmodule Mix.Tasks.Routex.Install do
    @shortdoc "Install `igniter` in order to install Routex."

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'routex.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
