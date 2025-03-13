defmodule Routex.RouterTest.Dummy do
  defmodule Router1 do
    use Routex.Router
    use Phoenix.Router

    get "/", FakeController, :new
  end
end

defmodule Routex.RouterTest do
  use ExUnit.Case

  alias Routex.Router
  alias Routex.RouterTest.Dummy

  test "private exposure functions" do
    Router.__supported_types__()
    Router.__unsupported_types__()
    Router.__default_types__()
  end

  test "routex plug is injected" do
    assert function_exported?(Dummy.Router1, :routex, 2)
  end
end
