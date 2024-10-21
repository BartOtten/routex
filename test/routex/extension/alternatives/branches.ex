defmodule Routex.Extension.Alternatives.BranchesTest do
  use ExUnit.Case
  alias Routex.Extension.Alternatives.Branches
  alias Routex.Test.Fixtures, as: F

  @branches_with_map_attrs F.branches_with_map_attrs()
  @branches_precomputed F.branches_precomputed()
  @branches F.branches()
  @branches_flat F.branches_flat()

  test "add_precomputed_values!/1 with map attrs adds precomputed values correctly" do
    assert Branches.add_precomputed_values!(@branches_with_map_attrs) == @branches_precomputed
  end

  test "add_precomputed_values!/1 with struct attrs adds precomputed values correctly" do
    assert Branches.add_precomputed_values!(@branches) == @branches_precomputed
  end

  test "flatten/1 returns a flat version of branches branches" do
    assert Branches.flatten(@branches_precomputed) == @branches_flat
  end
end
