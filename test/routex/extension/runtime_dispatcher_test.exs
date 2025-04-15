defmodule Routex.Extension.RuntimeDispatcherTest do
  use ExUnit.Case, async: true
  alias Routex.Extension.RuntimeDispatcher

  # Mock modules for testing
  defmodule MockLocale do
    def put_locale(locale), do: send(self(), {:put_locale_called, locale})
    def put_locale(backend, locale), do: send(self(), {:put_locale_called, backend, locale})
  end

  defmodule MockBackend do
    def config do
      %{
        __struct__: __MODULE__,
        dispatch_targets: [
          {MockLocale, :put_locale, [[:attrs, :language]]},
          {MockLocale, :put_locale, [MockBackend, [:attrs, :region]]}
        ]
      }
    end
  end

  # Helper function to create halper module
  def create_helper_mod(mod) do
    result = RuntimeDispatcher.create_helpers([], MockBackend, [])

    # Evaluate the generated code to test the dispatch_targets function
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
        dispatch_targets: [
          {MockLocale, :non_existing, [[:attrs, :language]]}
        ]
      ]

      assert_raise RuntimeError, ~r/does not provide/, fn ->
        RuntimeDispatcher.configure(opts, MockBackend)
      end
    end

    test "returns the opts unchanged" do
      opts = [
        dispatch_targets: [
          {MockLocale, :put_locale, [[:attrs, :language]]}
        ]
      ]

      assert opts == RuntimeDispatcher.configure(opts, MockBackend)
    end
  end

  describe "plug/3" do
    test "calls dispatch_targets with attributes from connection" do
      create_helper_mod(A)
      conn = %{private: %{routex: %{language: "nl", region: "be"}}}
      attrs = %{__helper_mod__: A}

      assert %{private: %{routex: %{language: "nl", region: "be"}}} =
               RuntimeDispatcher.plug(conn, [], attrs)

      # Verify that put_locale was called.
      assert_received {:put_locale_called, "nl"}
      assert_received {:put_locale_called, MockBackend, "be"}
    end
  end

  describe "handle_params/4" do
    test "calls dispatch_targets with attributes from socket" do
      create_helper_mod(B)
      socket = %{private: %{routex: %{language: "en", region: "uk"}}}
      attrs = %{__helper_mod__: B}

      assert {:cont, %{private: %{routex: %{language: "en", region: "uk"}}}} =
               RuntimeDispatcher.handle_params(nil, nil, socket, attrs)

      # Verify that put_locale was called.
      assert_received {:put_locale_called, "en"}
      assert_received {:put_locale_called, MockBackend, "uk"}
    end
  end
end
