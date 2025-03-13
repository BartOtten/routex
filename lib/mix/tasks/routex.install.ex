defmodule Mix.Tasks.Routex.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs Routex and configures a Routex backend with a dynamic list of extensions"
  end

  def example do
    "mix routex.install"
  end

  def long_doc do
    """
    #{short_doc()}

    This task installs Routex into your Phoenix project. It updates your web interface entrypoint,
    injects a helper function for Routex routes, and generates a default Routex backend module configured
    with the available extensions.

    ## Example

    ```bash
    #{example()}
    ```

    ## Options

    * `--example-option` or `-e` - Docs for your option
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Routex.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @extensions [
      Routex.Extension.AlternativeGetters,
      Routex.Extension.Alternatives,
      Routex.Extension.Assigns,
      Routex.Extension.AttrGetters,
      Routex.Extension.Interpolation,
      Routex.Extension.PhoenixLiveviewHooks,
      Routex.Extension.Plugs,
      Routex.Extension.RouteHelpers,
      Routex.Extension.VerifiedRoutes
    ]

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :routex,
        adds_deps: [{:routex, ">= 0.0.0"}],
        installs: [],
        example: __MODULE__.Docs.example(),
        only: nil,
        positional: [],
        composes: [],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      update_web_interface()
      create_routex_backend_file()
      preprocess_routes()

      igniter
      |> Igniter.add_notice("Routex installation complete. Please review the changes and update your configuration as needed.")
    end

    defp web_module_name do
      Mix.Project.config()[:app]
      |> to_string()
      |> Macro.camelize()
      |> Kernel.<>("Web")
    end

    defp web_entrypoint_file do
      "lib/#{Macro.underscore(web_module_name())}.ex"
    end

    defp web_directory do
      "lib/#{Macro.underscore(web_module_name())}"
    end

    defp update_web_interface do
      file = web_entrypoint_file()

      if File.exists?(file) do
        content = File.read!(file)

        content =
          content
          |> inject_use_routex_router()
          |> inject_on_mount()
          |> inject_helpers()

        File.write!(file, content)
        Mix.shell().info("Updated #{file} with Routex integration.")
      else
        Mix.shell().error("Could not find #{file}. Please update your project manually to use Routex.")
      end
    end

    defp inject_use_routex_router(content) do
      regex = ~r/(use Phoenix.Router, helpers: false)/
      String.replace(content, regex, "use Routex.Router\n\\1")
    end

    defp inject_on_mount(content) do
      web_mod = web_module_name()

      if String.contains?(content, "unquote(html_helpers())") do
        String.replace(content, "unquote(html_helpers())", """
        unquote(html_helpers())
        on_mount(unquote(#{web_mod}).Router.RoutexHelpers)
        """)
      else
        content
      end
    end

    defp inject_helpers(content) do
      web_mod = web_module_name()

      helper_code = """
      defp routex_helpers do
        quote do
          import #{inspect Module.concat([String.to_atom(web_mod), Router, RoutexHelpers])}, only: :macros
          alias #{inspect Module.concat([String.to_atom(web_mod), Router, RoutexHelpers])}, as: Routes
        end
      end
      """

      if String.contains?(content, "defp routex_helpers") do
        content
      else
        content <> "\n" <> helper_code
      end
    end

    defp create_routex_backend_file do
      extensions_code =
        @extensions
        |> Enum.map(&("    " <> inspect(&1)))
        |> Enum.join(",\n")

      web_mod = web_module_name()

      backend_module = """
      defmodule #{web_mod}.RoutexBackend do
        @moduledoc \"""
        This backend for Routex includes the following extensions:
      #{Enum.map_join(@extensions, "\n", fn ext -> "  - " <> inspect(ext) end)}
        \"""
        use Routex.Backend,
          extensions: [
      #{extensions_code}
          ]
      end
      """

      backend_path = Path.join(web_directory(), "routex_backend.ex")
      File.mkdir_p!(web_directory())
      File.write!(backend_path, backend_module)
      Mix.shell().info("Created #{backend_path} with default Routex backend configuration.")
    end

    defp preprocess_routes do
      file = "lib/#{Macro.underscore(web_module_name())}/router.ex"

      if File.exists?(file) do
        content = File.read!(file)

        content =
          content
          |> String.replace(~r/plug :fetch_current_user/, """
          plug :fetch_current_user
          plug :routex
          """)
          |> String.replace(~r/pipe_through :browser/, """
          pipe_through :browser
          preprocess_using #{web_module_name()}.RoutexBackend do
            # ...routes...
          end
          """)
          |> String.replace(~r/pipe_through \[:browser, :redirect_if_user_is_authenticated\]/, """
          pipe_through [:browser, :redirect_if_user_is_authenticated]
          preprocess_using #{web_module_name()}.RoutexBackend do
            # ...routes...
          end
          """)
          |> String.replace(~r/pipe_through \[:browser, :require_authenticated_user\]/, """
          pipe_through [:browser, :require_authenticated_user]
          preprocess_using #{web_module_name()}.RoutexBackend do
            # ...routes...
          end
          """)

        File.write!(file, content)
        Mix.shell().info("Updated #{file} with Routex route preprocessing.")
      else
        Mix.shell().error("Could not find #{file}. Please update your project manually to use Routex.")
      end
    end
  end
else
  defmodule Mix.Tasks.Routex.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

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
