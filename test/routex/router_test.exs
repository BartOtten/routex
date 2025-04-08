defmodule FakeController do
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule Routex.RouterTest.Dummy do
  defmodule RtxBackend do
    use Routex.Backend,
      extensions: [Routex.Extension.AttrGetters, Routex.Extension.VerifiedRoutes],
      verified_sigil_routex: "~p",
      verified_sigil_original: "~o"
  end

  defmodule Router1 do
    use Routex.Router
    use Phoenix.Router

    get "/", FakeController, :new

    preprocess_using RtxBackend do
      get "/routex", FakeController, :new
    end
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

  test "all routes are present" do
    assert [%{path: "/routex"}, %{path: "/"}] = Dummy.Router1.__routes__()
  end

  test "routex plug is injected" do
    assert function_exported?(Dummy.Router1, :routex, 2)
  end
end
