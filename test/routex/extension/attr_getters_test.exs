defmodule Routex.Extension.AttrGettersTest.HelpersModule do
  alias Routex.Extension.AttrGetters

  route =
    %Phoenix.Router.Route{private: %{}, path: "/foo/bar", trailing_slash?: false}
    |> Routex.Attrs.put(:rtx_1, "r1")
    |> Routex.Attrs.put(:rtx_2, "r2")

  ast = AttrGetters.create_helpers([route], Conf1, nil)

  # pattern = route |> Routex.Match.new() |> Routex.Match.to_pattern()
  # IO.inspect(pattern)
  # ast =
  # 	quote do
  # 		def attrs(unquote(pattern)) do
  # 			:foo
  # 		end
  # 	end

  Module.create(AttrGettersTestMod, ast, __ENV__)

  # mod_ast =
  #   quote do
  #     defmodule Foo do
  #       unquote(ast)
  #     end
  #   end

  # Code.eval_quoted(mod_ast, [], __ENV__)
end

defmodule Routex.Extension.AttrGettersTest do
  use ExUnit.Case, async: true
  require Routex.Extension.AttrGettersTest.HelpersModule
  alias Routex.Extension.AttrGettersTest.HelpersModule

  test "by default includes all attrs" do
    assert %{rtx_1: "r1", rtx_2: "r2"} =
             "/foo/bar"
             |> AttrGettersTestMod.attrs()
  end
end
