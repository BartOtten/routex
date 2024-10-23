defmodule Routex.DevTest do
  use ExUnit.Case
  import Routex.Dev
  import ExUnit.CaptureIO

  describe "escape_inspect/2" do
    test "prints escaped ast and returns ast" do
      ast = quote do: 1 + 4 = 5

      expected =
        "{:{}, [],\n [\n   :=,\n   [],\n   [\n     {:{}, [],\n      [\n        :+,\n        [context: Routex.DevTest, imports: [{1, Kernel}, {2, Kernel}]],\n        [1, 4]\n      ]},\n     5\n   ]\n ]}\n"

      assert {^ast, _} = with_io(fn -> inspect_ast(ast) end)
      assert expected == capture_io(fn -> inspect_ast(ast) end)
    end

    test "passes opts to IO.inspect/2" do
      ast = quote do: 1 + 4 = 5
      opts = [limit: 5]
      expected = "{:{}, [], [:=, [], ...]}\n"

      assert expected == capture_io(fn -> inspect_ast(ast, opts) end)
    end
  end

  describe "print_ast/2" do
    ast = quote do: 1 + 4 = 5
    expected = "1 + 4 = 5\n"

    assert ast == print_ast(ast)
    assert expected == capture_io(fn -> print_ast(ast) end)
  end
end
