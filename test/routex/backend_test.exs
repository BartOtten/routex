# Dummy extensions that simply add a key to the options.
defmodule Routex.BackendTest.DummyExtension1 do
  @moduledoc false
  @behaviour Routex.Extension

  @impl Routex.Extension
  def configure(opts, _backend) do
    Routex.Extension.Preset.merge([dummy1: true], opts, __MODULE__)
  end
end

defmodule Routex.BackendTest.DummyExtension2 do
  @moduledoc false
  @behaviour Routex.Extension

  @impl Routex.Extension
  def configure(opts, _backend) do
    Routex.Extension.Preset.merge([dummy2: true], opts, __MODULE__)
  end
end

defmodule Routex.BackendTest.DummyExtensionPrint do
  @moduledoc false
  @behaviour Routex.Extension

  @impl Routex.Extension
  def configure(opts, _backend) do
    # Disabled due to inability to capture a captured input
    # Routex.Utils.print("MESSAGE")
    opts
  end
end

defmodule Routex.BackendTest.DummyPreset do
  @moduledoc false
  @behaviour Routex.Extension

  @impl Routex.Extension
  def configure(config, _backend) do
    preset = [
      extensions: [
        Routex.BackendTest.DummyExtension2,
        Routex.BackendTest.DummyExtension1
      ],
      preset1: true
    ]

    Routex.Extension.Preset.merge(preset, config, __MODULE__)
  end
end

# Define a minimal Routex.Extension module to supply the default callbacks.
defmodule Routex.BackendTest.Routex.Extension do
  @moduledoc false
  # Return a list with one callback: :configure with arity 2.
  def behaviour_info(:callbacks), do: [configure: 2]
end

# Create a test backend module using the __using__ macro.
defmodule Routex.BackendTest.TestBackend1 do
  @moduledoc false
  use Routex.Backend,
    extensions: [Routex.BackendTest.DummyExtension1, Routex.BackendTest.DummyExtension2],
    other_option: "value"
end

# Create a test backend module using the __using__ macro.
defmodule Routex.BackendTest.TestBackend2 do
  @moduledoc false
  use Routex.Backend,
    extensions: [Routex.BackendTest.DummyExtension2, Routex.BackendTest.DummyPreset],
    other_option: "value",
    dummy1: false
end

# Create a test backend module using the __using__ macro.
defmodule Routex.BackendTest.TestBackendPrint do
  @moduledoc false
  use Routex.Backend,
    extensions: [Routex.BackendTest.DummyExtensionPrint]
end

defmodule Routex.BackendTest do
  @moduledoc false
  use ExUnit.Case

  alias __MODULE__, as: M

  describe "generated backend configuration" do
    test "config/0 returns a struct with options modified by extensions" do
      config = M.TestBackend1.config()

      # Check that the original option is preserved…
      assert config.other_option == "value"
      # …and that each extension's configure/2 has been applied.
      assert config.dummy1 == true
      assert config.dummy2 == true
    end

    test "extensions/0 returns a deduplicated list of extensions" do
      exts = M.TestBackend1.extensions() |> Enum.sort()
      expected = [M.DummyExtension1, M.DummyExtension2] |> Enum.sort()
      assert exts == expected
    end

    test "callbacks/0 returns a map with callbacks mapped to extension modules" do
      callbacks = M.TestBackend1.callbacks()
      # Our default callbacks include only :configure.
      assert Map.has_key?(callbacks, :configure)
      exts = callbacks[:configure] |> Enum.sort()
      expected = [M.DummyExtension1, M.DummyExtension2] |> Enum.sort()
      assert exts == expected
    end

    test "presets are expanded" do
      config = M.TestBackend2.config()

      exts = M.TestBackend1.extensions() |> Enum.sort()
      expected = [M.DummyExtension1, M.DummyExtension2] |> Enum.sort()
      assert exts == expected

      # Check that the original option is preserved…
      assert config.other_option == "value"
      # …and that each extension's configure/2 has been applied.
      assert config.dummy1 == false
      assert config.dummy2 == true
      assert config.preset1 == true
    end

    test "duplicate calls to a configure/2 callback do not cause duplicate print" do
      _output =
        ExUnit.CaptureIO.capture_io(fn ->
          _config = M.TestBackendPrint.config()
          _config = M.TestBackendPrint.config()
        end)

      # TODO: find a way to capture the already captured output
      # assert output == ">> MESSAGE"
    end
  end
end
