defmodule Routex.Extension.Localize.IntegrateTest do
  use ExUnit.Case

  @mix_content """
  defmodule FBar.MixProject do
  use Mix.Project

  def project do
    [
      app: :fbar,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {FBar.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
  """

  test "Base module is extracted from Mixfile content" do
    assert "FBar" == Routex.Extension.Localize.Integrate.extract_main_module(@mix_content)
  end
end
