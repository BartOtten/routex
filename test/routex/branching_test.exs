# The module with the original macro
defmodule Routex.BranchingTest.MyMacros do
  defmacro my_macro(path_segments) do
    quote do
      unquote(Path.join(path_segments))
    end
  end
end

# A module which can be required to trigger the creation of the
# module with branched macro's.
defmodule Routex.BranchingTest.Routex do
  match_binding =
    quote do
      var!(variant)
    end

  ast =
    Routex.Branching.branch_macro(
      ["en", "nl"],
      match_binding,
      {Routex.BranchingTest.PreCompiled, :transform_arg, []},
      Routex.BranchingTest.MyMacros,
      :my_macro,
      as: :branched_macro
    )

  Module.create(Routex.BranchingTest.Branched, ast, Macro.Env.location(__ENV__))
end

# A module with a transform function; should be 'required' before the transformation takes place.
defmodule Routex.BranchingTest.PreCompiled do
  def transform_arg(pattern, branched_arg) do
    ["/europe", "/" <> pattern | branched_arg]
  end
end

# Module mimicking real app module adapted for branched macro support
defmodule Routex.BranchingTest.MyModule do
  require Routex.BranchingTest.Routex

  require Routex.BranchingTest.MyMacros
  import Routex.BranchingTest.Branched
  # 	require Routex.BranchingTest.Compiled

  def original(variant) do
    _ = variant
    my_macro(["/my/macro", "path"])
  end

  def branched(variant) do
    _ = variant
    branched_macro(["/my/macro", "path"])
  end
end

defmodule Routex.BranchingTest do
  use ExUnit.Case
  require __MODULE__.Routex

  test "original" do
    assert Routex.BranchingTest.MyModule.original("en") == "/my/macro/path"
  end

  test "branching nl" do
    assert Routex.BranchingTest.MyModule.branched("nl") == "/europe/nl/my/macro/path"
  end

  test "branching en" do
    assert Routex.BranchingTest.MyModule.branched("en") == "/europe/en/my/macro/path"
  end
end
