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
  Returns the ast to get the last value in the order list
  """
  @spec get_helper_ast(caller :: Macro.Env.t()) :: Macro.output()
  def get_helper_ast(caller) do
		IO.inspect(caller.module, label: :MODULE)
		IO.inspect(caller.versioned_vars, label: :VVARS)
    vars =
      caller.versioned_vars
      |> Enum.filter(fn
        {{var, _}, _} when var in [:socket, :conn, :assigns] ->
          true

        _other ->
          false
      end)
      |> Enum.map(fn {{var, _}, _} -> var end) |> IO.inspect(label: :VARS)

    cond do
      :assigns in vars ->
        quote do
          case var!(assigns) do
            %{conn: %{private: %{routex: %{__order__: order}}}} ->
              List.last(order)

            %{__order__: order} ->
              List.last(order)
          end
        end

      :conn in vars ->
        quote do
          var!(conn).private.routex.__order__ |> List.last()
        end

      :socket in vars ->
        quote do
          case var!(socket) do
            %{private: %{routex: %{__order__: order}}} ->
              List.last(order)

            %{private: %{connect_info: %{private: %{routex: %{__order__: order}}}}} ->
              List.last(order)

            _ ->
              require Logger

              Logger.warning("""
              Using branching verified routes in `mount/3` is not supported.
              Please move the code to the `handle_params/3`.
              """)

              {:current_stacktrace, st} = Process.info(self(), :current_stacktrace)
              st |> tl |> Exception.format_stacktrace() |> Logger.warning()

              0
          end
        end

      # ExUnit.Callbacks in caller.requires ->
      #   quote do
      #     require Logger
      #     Logger.warning("No match for helper AST, set manual __order__")
			# 		try do
			# 			var!(__order__)
			# 		rescue
			# 			e -> IO.inspect(e)
			# 				0
			# 		end
      #   end

      true ->
        quote do
          require Logger
          Logger.critical("No helper ast found. Fall back to process key :rtx_scope")
          Process.get(:rtx_scope, 0)
        end
    end
  end
end
