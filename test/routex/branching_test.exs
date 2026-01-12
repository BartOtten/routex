defmodule ExternalPackage.Macros do
  @moduledoc """
  The module with the original macro. The macro has two arities.
  """
  defmacro original_macro(_arg1, path_segments, _other_path_segments) do
    quote do
      unquote(Path.join(path_segments))
    end
  end

  defmacro original_macro(_arg1, _arg2, path_segments, other_path_segments) do
    quote do
      unquote(Path.join([path_segments, other_path_segments]))
    end
  end

  defmacro test_macro(), do: []
end

defmodule Routex.BranchingTest.Routex do
  @moduledoc """
  A module which can be required in another module to trigger the creation of module with branched macro's.
  """

  defmodule Transformers do
    @moduledoc "Transformers are put in separate (child) module so they can be compiled before being called by the macro."

    def transform_clause("de", _branched_arg), do: :noop
    def transform_clause(pattern, _branched_arg), do: pattern

    def transform_arg(_pattern, ["/my/macro", "/arg/causing_transform_noop"]), do: :noop
    def transform_arg(pattern, branched_arg), do: ["/europe", "/" <> pattern | branched_arg]
  end

  match_binding =
    _in_current_ctx =
    quote do
      _in_macro_ctx =
        quote do
          _in_caller_context = var!(variant)
        end
    end

  ast =
    Routex.Branching.branch_macro(
      ExternalPackage.Macros,
      :original_macro,
      match_binding,
      ["en", "nl", "de"],
      name_passthrough: :passthrough_macro,
      name_branched: :branched_macro,
      param_position: fn arity -> arity - 1 end,
      clause_transformer: &__MODULE__.Transformers.transform_clause/2,
      # deprecated variant
      argument_transformer: {__MODULE__.Transformers, :transform_arg, [:foo]}
    )

  _deprecated =
    Routex.Branching.branch_macro(
      ExternalPackage.Macros,
      :test_macro,
      match_binding,
      ["en", "nl", "de"],
      orig: :depr_passthrough_key,
      as: :test_branched_key,
      arg_pos: fn arity -> arity - 1 end,
      clause_transformer: &__MODULE__.Transformers.transform_clause/2,
      # deprecated variant
      argument_transformer: {__MODULE__.Transformers, :transform_arg, [:foo]}
    )

  Module.create(Routex.BranchingTest.Branched, ast, Macro.Env.location(__ENV__))
end

defmodule Routex.BranchingTest.MyModule do
  @moduledoc """
  Module mimicking real app module adapted for branched macro support
  """

  require Routex.BranchingTest.Routex

  import ExternalPackage.Macros
  import Routex.BranchingTest.Branched

  def original(variant) do
    _ignored = variant
    original_macro([:foo], ["/my/macro", "/path"], ["foo"])
  end

  def original(variant, _v2) do
    _used_in_macro = variant
    original_macro([:foo], [:bar], ["/my/macro", "/path"], ["foo"])
  end

  def passthrough(variant) do
    _ignored = variant
    passthrough_macro([:foo], ["/my/macro", "/path"], ["foo"])
  end

  def passthrough(variant, _v2) do
    _used_in_macro = variant
    passthrough_macro([:foo], [:bar], ["/my/macro", "/path"], ["foo"])
  end

  def branched(variant) do
    _used_in_macro = variant
    branched_macro([:foo], ["/my/macro", "/path"], ["foo"])
  end

  def branched(variant, _v2) do
    _used_in_macro = variant
    branched_macro([:foo], [:bar], ["/my/macro", "/path"], ["foo"])
  end

  def branched_noop_arg() do
    variant = :ignored
    _used_in_macro = variant
    branched_macro([:foo], ["/my/macro", "/arg/causing_transform_noop"], ["foo"])
  end
end

defmodule Routex.BranchingTest do
  @moduledoc false
  use ExUnit.Case
  require __MODULE__.Routex

  alias Routex.BranchingTest.MyModule

  test "original returns original" do
    for variant <- ["en", "nl", "fr", "de"] do
      assert MyModule.original(variant) == "/my/macro/path"
      assert MyModule.original(variant, "other") == "/my/macro/path/foo"
    end
  end

  test "passthrough returns original" do
    assert MyModule.passthrough("en") == MyModule.original("en")
    assert MyModule.passthrough("en", "other") == MyModule.original("en", "other")
    assert MyModule.passthrough("nl") == MyModule.original("nl")
    assert MyModule.passthrough("nl", "other") == MyModule.original("nl", "other")
    assert MyModule.passthrough("en") == MyModule.original("en")
    assert MyModule.passthrough("de", "other") == MyModule.original("de", "other")
  end

  test "branching 'nl' returns 'nl' paths" do
    assert MyModule.branched("nl") == "/europe/nl/my/macro/path"
    assert MyModule.branched("nl", "other") == "/europe/nl/my/macro/path/foo"
  end

  test "branching 'en' returns 'en' paths" do
    assert MyModule.branched("en") == "/europe/en/my/macro/path"
    assert MyModule.branched("en", "other") == "/europe/en/my/macro/path/foo"
  end

  test ":noop branche 'de' is non existing" do
    assert_raise CaseClauseError, fn -> MyModule.branched("de") end
    assert_raise CaseClauseError, fn -> MyModule.branched("de", "other") end
  end

  test ":noop argument [\"/my/macro\", \"/arg/causing_transform_noop\"] is not transformed" do
    # MyModule.branched_noop_arg/1 calls the branch creator with an argument which
    # results in a :noop by the argument transformer. As a result the argument is
    # returned without transformation.
    assert MyModule.branched_noop_arg() == "/my/macro/arg/causing_transform_noop"
    assert MyModule.branched_noop_arg() == "/my/macro/arg/causing_transform_noop"
  end
end
