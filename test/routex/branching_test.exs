defmodule Routex.BranchingTest.OriginalMacros do
  @moduledoc """
  The module with the original macro with two arities
  """

  defmacro original_macro(path_segments) do
    quote do
      unquote(Path.join(path_segments))
    end
  end

  defmacro original_macro(path_segments, other_path_segments) do
    quote do
      unquote(Path.join([path_segments, other_path_segments]))
    end
  end
end

defmodule Routex.BranchingTest.Routex do
  @moduledoc """
  A module which can be required in another module to trigger the creation of module with branched macro's.
  """

  # current level
  # into branching ast level
  match_binding =
    quote do
      # into caller level
      quote do
        var!(variant)
      end
    end

  ast =
    Routex.Branching.branch_macro(
      ["en", "nl"],
      match_binding,
      {Routex.BranchingTest.PreCompiled, :transform_clause, []},
      {Routex.BranchingTest.PreCompiled, :transform_arg, []},
      Routex.BranchingTest.OriginalMacros,
      :original_macro,
      as: :branched_macro
    )

  Module.create(Routex.BranchingTest.Branched, ast, Macro.Env.location(__ENV__))
end

defmodule Routex.BranchingTest.PreCompiled do
  @moduledoc """
  A module with a transform function; should be 'required' before the transformation takes place.
  """

  def transform_clause(pattern, _branched_arg), do: pattern

  def transform_arg(pattern, branched_arg) do
    ["/europe", "/" <> pattern | branched_arg]
  end
end

defmodule Routex.BranchingTest.MyModule do
  @moduledoc """
  Module mimicking real app module adapted for branched macro support
  """

  require Routex.BranchingTest.Routex
  require Routex.BranchingTest.OriginalMacros

  import Routex.BranchingTest.Branched

  def original(variant) do
    _ = variant
    original_macro(["/my/macro", "/path"])
  end

  def original(variant, _v2) do
    _ = variant
    original_macro(["/my/macro", "/path"], ["foo"])
  end

  def branched(variant) do
    _ = variant
    branched_macro(["/my/macro", "/path"])
  end

  def branched(variant, _v2) do
    _ = variant
    branched_macro(["/my/macro", "/path"], ["foo"])
  end
end

defmodule Routex.BranchingTest do
  use ExUnit.Case
  require __MODULE__.Routex

  test "original" do
    assert Routex.BranchingTest.MyModule.original("en") == "/my/macro/path"
    assert Routex.BranchingTest.MyModule.original("en", "other") == "/my/macro/path/foo"
  end

  test "branching nl" do
    assert Routex.BranchingTest.MyModule.branched("nl") == "/europe/nl/my/macro/path"
    assert Routex.BranchingTest.MyModule.branched("nl", "other") == "/europe/nl/my/macro/path/foo"
  end

  test "branching en" do
    assert Routex.BranchingTest.MyModule.branched("en") == "/europe/en/my/macro/path"
    assert Routex.BranchingTest.MyModule.branched("en", "other") == "/europe/en/my/macro/path/foo"
  end
end
