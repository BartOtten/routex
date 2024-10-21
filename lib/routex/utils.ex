defmodule Routex.Utils do
  @moduledoc """
  Provides an interface to functions which can be used in extensions.
  """

  @doc """
  Prints an indented text. Should be used when printing messages in
  the terminal during compile time.
  """
  @spec print(input :: iodata) :: binary
  def print(input), do: IO.puts([">> " | input])

  @doc """
  Returns the AST to get the current branch from process dict or from  assigns, conn or socket
  based on the available variables in the __CALLER__ module.
  """
  @spec get_helper_ast(caller :: Macro.Env.t()) :: Macro.output()
  def get_helper_ast(caller) do
    quote do
      if branch = Process.get(:rtx_branch) do
        branch
      else
        unquote(get_derived_ast(caller))
      end
    end
  end

  defp get_derived_ast(caller) do
    vars = list_available_module_vars(caller)

    cond do
      :assigns in vars ->
        quote do
          assigns = var!(assigns)
          Routex.Utils.get_branch(assigns[:conn] || assigns[:socket])
        end

      :conn in vars ->
        quote do
          var!(conn) |> Routex.Utils.get_branch()
        end

      :socket in vars ->
        quote do
          var!(socket) |> Routex.Utils.get_branch()
        end

      ExUnit.Callbacks in caller.requires ->
        0

      true ->
        require Logger

        Logger.warning(
          "#{caller.module}: No helper AST and no proces key `:rtx_branch` found. Fallback to `0`"
        )

        0
    end
  end

  def get_branch(%{private: %{routex: %{__branch__: branch}}}) do
    List.last(branch)
  end

  def get_branch(_) do
    require Logger

    Logger.warning("""
    Using branching verified routes in `mount/3` is not supported.
    Please move the code to the `handle_params/3`.
    """)

    {:current_stacktrace, st} = Process.info(self(), :current_stacktrace)
    st |> tl |> Exception.format_stacktrace() |> Logger.warning()

    0
  end

  defp list_available_module_vars(caller) do
    caller.versioned_vars
    |> Enum.filter(fn
      {{var, _}, _} when var in [:socket, :conn, :assigns] ->
        true

      _other ->
        false
    end)
    |> Enum.map(fn {{var, _}, _} -> var end)
  end
end