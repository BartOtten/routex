defmodule Routex.Extension.RuntimeCallbacksTest do
  use ExUnit.Case, async: true
  alias Routex.Extension.RuntimeCallbacks

  # Mock modules for testing
  defmodule MockLocale do
    def put_locale(locale), do: send(self(), {:put_locale_called, locale})
    def put_locale(backend, locale), do: send(self(), {:put_locale_called, backend, locale})
  end

  defmodule MockBackend do
    def config do
      %{
        __struct__: __MODULE__,
        runtime_callbacks: [
          {MockLocale, :put_locale, [[:attrs, :language]]},
          {MockLocale, :put_locale, [MockBackend, [:attrs, :region]]}
        ]
      }
    end
  end

  # Helper function to create halper module
  def create_helper_mod(mod) do
    result = RuntimeCallbacks.create_helpers([], MockBackend, [])

    # Evaluate the generated code to test the runtime_callbacks function
    Code.eval_quoted(
      quote do
        defmodule unquote(mod) do
          unquote(result)
        end
      end
    )
  end

  describe "config/3" do
    test "raises when callback is not exported" do
      opts = [
        runtime_callbacks: [
          {MockLocale, :non_existing, [[:attrs, :language]]}
        ]
      ]

      assert_raise RuntimeError, ~r/does not provide/, fn ->
        result = RuntimeCallbacks.configure(opts, MockBackend)
      end
    end

    test "returns the opts unchanged" do
      opts = [
        runtime_callbacks: [
          {MockLocale, :put_locale, [[:attrs, :language]]}
        ]
      ]

      assert opts == RuntimeCallbacks.configure(opts, MockBackend)
    end
  end

  describe "plug/3" do
    test "calls runtime_callbacks with attributes from connection" do
      create_helper_mod(A)
      conn = %{private: %{routex: %{language: "nl", region: "be"}}}
      attrs = %{__helper_mod__: A}

      assert %{private: %{routex: %{language: "nl", region: "be"}}} =
               RuntimeCallbacks.plug(conn, [], attrs)

      # Verify that put_locale was called.
      assert_received {:put_locale_called, "nl"}
      assert_received {:put_locale_called, MockBackend, "be"}
    end
  end

  describe "handle_params/4" do
    test "calls runtime_callbacks with attributes from socket" do
      create_helper_mod(B)
      socket = %{private: %{routex: %{language: "en", region: "uk"}}}
      attrs = %{__helper_mod__: B}

      assert {:cont, %{private: %{routex: %{language: "en", region: "uk"}}}} =
               RuntimeCallbacks.handle_params(nil, nil, socket, attrs)

      # Verify that put_locale was called.
      assert_received {:put_locale_called, "en"}
      assert_received {:put_locale_called, MockBackend, "uk"}
    end
  end
end
