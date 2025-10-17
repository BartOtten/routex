if Code.ensure_loaded?(Gettext) do
  defmodule Mix.Tasks.Gettext.Extract.Routex do
    @shortdoc "Force translatable segments extraction"
    @moduledoc """
    A Mix task to force extraction of Gettext translatable segments.
    """
    use Mix.Task
    @recursive false

    def run(args) do
      _status = Application.ensure_all_started(:gettext)
      force_recompile_with_extractor()

      Mix.Task.run("gettext.extract", args)
    end

    defp force_recompile_with_extractor do
      Gettext.Extractor.enable()
      Mix.Task.run("compile", ["--force"])
    after
      Gettext.Extractor.disable()
    end
  end
end
