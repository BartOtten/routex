defmodule Routex.ProcessingTest do
  use ExUnit.Case

  # TODO: Do not depend on actual compilation for testing Processing.
  defmodule RtxBackend do
    use(Routex.Backend, extensions: [])
  end

  test "an error is raised when no attrs/1 available" do
    true
  end

  test ":assigns is optional" do
    true
  end
end
