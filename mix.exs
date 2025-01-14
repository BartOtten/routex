defmodule Routex.MixProject do
  use Mix.Project

  @source_url "https://github.com/BartOtten/routex"
  @version "1.0.0"
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
      consolidate_protocols: Mix.env() != :test,
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
      {:phoenix, ">= 1.7.0"}
    ]
  end

  defp dev_deps do
    [
      {:phoenix_view, ">= 2.0.0", optional: true},
      {:phoenix_live_view, "~> 0.18 or ~> 1.0", optional: true},
      {:gettext, ">= 0.26.0", optional: true},
      {:phoenix_html_helpers, "~> 1.0"},
      {:jason, "~> 1.0", only: [:dev, :test], optional: true},
      {:ex_doc, "~> 0.34", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:floki, ">= 0.30.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:makeup_diff, "~> 0.1.0", only: [:dev]},
      {:git_ops, "~> 2.6.3", only: [:dev]},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Bart Otten"],
      licenses: ["MIT"],
      files:
        ~w(lib .formatter.exs mix.exs README.md LICENSE.md
                CHANGELOG.md CONTRIBUTING.md USAGE.md EXTENSIONS.md TROUBLESHOOTING.md EXTENSION_SUMMARIES.md TUTORIAL_LOCALIZED_ROUTES.md),
      links: %{
        Changelog: "https://hexdocs.pm/routex/changelog.html",
        GitHub: "https://github.com/BartOtten/routex"
      }
    ]
  end

  defp description() do
    "Extension driven superpowers for Phoenix Routes"
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      assets: %{"assets" => "assets"},
      before_closing_head_tag: &docs_before_closing_head_tag/1,
      extras: [
        "README.md",
        "USAGE.md",
        "CHANGELOG.md",
        "EXTENSIONS.md",
        "TROUBLESHOOTING.md",
        "EXTENSION_SUMMARIES.md",
        "TUTORIAL_LOCALIZED_ROUTES.md"
      ],
      filter_modules: ~r"Elixir.Routex.*$",
      groups_for_modules: [
        Routex: ~r"Routex\.?[^.]*$",
        Extensions: ~r"Routex.Extension\.[^.]*$",
        Submodules: ~r"Routex.Extension\..*\.*$"
      ],
      nest_modules_by_prefix: [
        Routex.Extension.Alternatives,
        Routex.Extension
      ],
      skip_undefined_reference_warnings_on: &String.match?(&1, ~r/Phoenix.Router.Route/),
      skip_code_autolink_to: &String.match?(&1, ~r/Phoenix.Router.Route/)
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
