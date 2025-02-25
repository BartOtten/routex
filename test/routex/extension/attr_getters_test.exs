defmodule Routex.Extension.AttrGettersTest.HelpersModule do
  alias Routex.Extension.AttrGetters

  @path "/foo/bar"

  route =
    %Routex.Route{private: %{}, path: @path, trailing_slash?: false}
    |> Routex.Attrs.put(:rtx_1, "r1")
    |> Routex.Attrs.put(:rtx_2, "r2")

  ast = AttrGetters.create_helpers([route], Conf1, nil)

  Module.create(AttrGettersTestMod, ast, __ENV__)
end

defmodule Routex.Extension.AttrGettersTest do
  use ExUnit.Case, async: true

  require Routex.Extension.AttrGettersTest.HelpersModule

  @path "/foo/bar"

  test "by default includes all attrs" do
    assert %{rtx_1: "r1", rtx_2: "r2"} = AttrGettersTestMod.attrs(@path)
  end
end
