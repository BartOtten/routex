# Define a minimal Routex.Extension module to supply the default callbacks.
defmodule Routex.BackendTest.Dummy do
  defmodule Extension1 do
    @moduledoc false
    @behaviour Routex.Extension

    def configure(opts, _env), do: Keyword.put(opts, :dummy1, true)
  end

  defmodule Extension2 do
    @moduledoc false
    @behaviour Routex.Extension

    def configure(opts, _env), do: Keyword.put(opts, :dummy2, true)
    def transform(routes, _backend, _env), do: routes
  end

  defmodule ExtensionNesting do
    @moduledoc false
    @behaviour Routex.Extension

    def configure(opts, _env),
      do: Keyword.update(opts, :extensions, [Extension2], &[Extension2 | &1])
  end

  for i <- 0..20 do
    module = Module.concat(ExtensionNesting, "Mod#{i}")
    module_plus = Module.concat(ExtensionNesting, "Mod#{i + 1}")

    ast =
      quote do
        defmodule unquote(module) do
          @moduledoc false
          @behaviour Routex.Extension

          def configure(opts, _env),
            do:
              Keyword.update(
                opts,
                :extensions,
                [unquote(module), unquote(module_plus)],
                &[unquote(module_plus) | &1]
              )
        end
      end

    Code.eval_quoted(ast)
  end

  # Create a test backend module using the __using__ macro.
  defmodule Backend1 do
    @moduledoc false
    use Routex.Backend,
      extensions: [Extension1, Extension2],
      other_option: "value"
  end
end

defmodule Routex.BackendTest do
  @moduledoc false
  use ExUnit.Case

  alias __MODULE__, as: M
  alias M.Dummy
  alias Routex.Backend

  describe "generated backend configuration" do
    test "config/0 returns a struct with options modified by extensions" do
      config = Dummy.Backend1.config()

      # Check that the original option is preserved…
      assert config.other_option == "value"
      # …and that each extension's configure/2 has been applied.
      assert config.dummy1 == true
      assert config.dummy2 == true
    end

    test "extensions/0 returns a deduplicated list of extensions" do
      exts = Dummy.Backend1.extensions() |> Enum.sort()
      expected = [Dummy.Extension1, Dummy.Extension2] |> Enum.sort()
      assert exts == expected
    end

    test "callbacks/0 returns a map with callbacks mapped to extension modules" do
      callbacks = Dummy.Backend1.callbacks()
      # Our default callbacks include only :configure and transform
      assert Map.has_key?(callbacks, :configure)
      assert Map.has_key?(callbacks, :transform)

      exts1 = callbacks[:configure] |> Enum.sort()
      expected1 = [Dummy.Extension1, Dummy.Extension2] |> Enum.sort()
      assert exts1 == expected1

      exts2 = callbacks[:transform] |> Enum.sort()
      expected2 = [Dummy.Extension2] |> Enum.sort()
      assert exts2 == expected2
    end
  end

  describe "preparation of options" do
    test "raise when an extension is missing" do
      opts = [extensions: [NonExisting.Extension]]

      assert_raise(CompileError, "Extension NonExisting.Extension not found.", fn ->
        Backend.prepare_unquoted(opts, FakeBackend)
      end)
    end

    test "opts are merged" do
      opts = [__backend__: FakeBackend, unknown: :value]
      new_opts = Backend.prepare_unquoted(opts, FakeBackend)

      assert new_opts[:__backend__] == FakeBackend
      assert new_opts[:unknown] == :value
    end

    test "reductions are counted" do
      opts = [__backend__: FakeBackend, unknown: :value]
      new_opts = Backend.prepare_unquoted(opts, FakeBackend)

      assert new_opts[:__backend__] == FakeBackend
      assert new_opts[:unknown] == :value
    end

    test "reductions are limited" do
      opts = [__backend__: FakeBackend, extensions: [Dummy.ExtensionNesting.Mod0]]

      assert_raise(
        CompileError,
        "Elixir.FakeBackend: Reduction limit exceeded (max. 10 reductions).",
        fn ->
          Backend.prepare_unquoted(opts, FakeBackend)
        end
      )
    end

    test "duplicate calls to a configure/2 callback do not cause duplicate print" do
      defmodule Dummy.ExtensionPrint do
        @moduledoc false
        @behaviour Routex.Extension

        def configure(opts, _env) do
          Routex.Utils.print("Do not print me twice")
          opts
        end
      end

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Backend.apply_callback_for_extensions(
            :configure,
            [Dummy.ExtensionPrint, Dummy.ExtensionPrint],
            []
          )
        end)

      assert output == ":: Do not print me twice\e[0m\n"
    end
  end
end
