defmodule Mix.Tasks.Routex.Trace do
  @shortdoc "Tracing Routex Compilation"

  @moduledoc """
  Tracing Routex Compilation
  """

  use Mix.Task
  # @recursive false

  @impl Mix.Task
  def run(_args) do
    IO.puts("HELLO")
    :ets.new(:schemas, [:named_table, :public])
    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", RtxTracer])
  end
end

defmodule RtxTracer do
  @moduledoc """
  Some doc
  """
  # @spec trace(tuple, Macro.Env.t()) :: :ok
  # def trace({:remote_macro, _meta, MyApp.Schema, :__using__, 1}, env) do
  #   :ets.insert(:schemas, {env.module, true})
  #   :ok
  # end

  # def trace({:remote_macro, meta, Ecto.Schema, :__using__, 1}, env) do
  #   case :ets.lookup(:schemas, env.module) do
  #     [] -> IO.warn("#{env.file}:#{meta[:line]} - #{inspect(env.module)} should use `MyApp.Schema`", [])
  #     _ -> :ok
  #   end
  # end
  def trace({_, _meta, ExampleWeb.Router.RoutexHelpers, _, _} = a, env) do
    IO.puts("#{inspect(a)} -> #{inspect(env.module)}")
    :ok
  end

  def trace(_, _), do: :ok
end
