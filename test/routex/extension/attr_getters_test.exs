defmodule Routex.Extension.AttrGettersTestInit do
  # alias Routex.Extension.AttrGetters

  # route =
  #   %Phoenix.Router.Route{private: %{}, path: "/foo/bar"}
  #   |> Routex.Attrs.put(:rtx_1, "r1")
  #   |> Routex.Attrs.put(:rtx_2, "r2")

  # ast = AttrGetters.create_helpers([route], Conf1, nil)

  # Module.create(:AttrGettersTestMod, ast, __ENV__)

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
  require Routex.Extension.AttrGettersTestInit

  # TODO: How?
  #
  # test "by default includes all attrs" do
  #   alias Routex.Extension.AttrGetters

  #   assert(:foo = Foo.attrs("/foo/bar"))
  # end
end
