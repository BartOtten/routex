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

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :routex,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example()
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      web = Igniter.Libs.Phoenix.web_module(igniter)
      routex_backend = Module.concat(web, "RoutexBackend")

      igniter
      |> Igniter.Project.Deps.add_dep({:routex, "~> 1.1"})
      |> then(fn
        %{assigns: %{test_mode?: true}} = igniter ->
          igniter

        igniter ->
          Igniter.apply_and_fetch_dependencies(igniter,
            error_on_abort?: true,
            yes_to_deps: true
          )
      end)
      |> Igniter.Project.Module.create_module(routex_backend, """
      use Routex.Backend,
      extensions: [Routex.Extension.AttrGetters]
      """)
    end
  end
else
  defmodule Mix.Tasks.Routex.Install do
    @shortdoc "Install `igniter` in order to install Oban."

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
