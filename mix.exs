defmodule Routex.MixProject do
  use Mix.Project

  @source_url "https://github.com/BartOtten/routex"
  @version "0.1.0-alpha.5"
  @name "Phoenix Routes Extension Framework"

  def project do
    [
      app: :routex,
      version: @version,
      elixir: "~> 1.11",
      deps: deps() ++ dev_deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: compilers(Mix.env()),
      dialyzer: dialyzer(),
      # Docs
      name: @name,
      description: description(),
      source_url: @source_url,
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "phx.routes": :test,
        compile: :test,
        "gettext.extract": :test,
        "gettext.merge": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    if Mix.env() == :test, do: Application.put_env(:phoenix, :json_library, Jason)

    [
      extra_applications: [:logger]
    ]
  end

  def aliases, do: [docs: ["docs", &copy_assets/1]]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:dev), do: ["lib"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp compilers(:test), do: Mix.compilers()
  defp compilers(_), do: Mix.compilers()

  defp dialyzer, do: [plt_add_apps: [:mix, :gettext, :phoenix_live_view]]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, ">= 1.6.0"},
      {:phoenix_view, ">= 2.0.0", optional: true},
      {:phoenix_live_view, ">= 0.16.0", optional: true},
      {:gettext, ">= 0.0.0", optional: true}
    ]
  end

  defp dev_deps do
    [
      {:jason, "~> 1.0", only: [:dev, :test], optional: true},
      {:ex_doc, "~> 0.29", only: [:dev, :test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:floki, ">= 0.30.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:makeup_diff, "~> 0.1.0", only: [:dev]},
      {:git_ops, "~> 2.5.6", only: [:dev]}
    ]
  end

  defp package do
    [
      maintainers: ["Bart Otten"],
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md
                CHANGELOG.md CONTRIBUTING.md USAGE.md EXTENSIONS.md TROUBLESHOOTING.md),
      links: %{
        Changelog: "https://hexdocs.pm/routex/changelog.html",
        GitHub: "https://github.com/BartOtten/routex"
      }
    ]
  end

  defp description() do
    "Extension framework to manipulate Phoenix Routes"
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      assets: "assets",
      before_closing_head_tag: &docs_before_closing_head_tag/1,
      extras: ["README.md", "USAGE.md", "CHANGELOG.md", "EXTENSIONS.md", "TROUBLESHOOTING.md"],
      filter_modules: ~r"Elixir.Routex\..*$",
      groups_for_modules: [
        Routex: ~r"Routex\.?[^.]*$",
        Extensions: ~r"Routex.Extension\.[^.]*$",
        Submodules: ~r"Routex.Extension\..*\.*$"
      ],
      nest_modules_by_prefix: [
        Routex.Extension.Alternatives,
        Routex.Extension
      ]
    ]
  end

  defp copy_assets(_) do
    File.cp_r("assets", "doc/assets")
  end

  defp docs_before_closing_head_tag(:html) do
    ~s{<link rel="stylesheet" href="assets/doc.css">}
  end

  defp docs_before_closing_head_tag(_), do: ""
end
