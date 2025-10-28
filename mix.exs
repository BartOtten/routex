defmodule Routex.MixProject do
  use Mix.Project

  @source_url "https://github.com/BartOtten/routex"
  @version "1.3.0-rc.1"
  @name "Routex"

  def project do
    [
      app: :routex,
      version: @version,
      elixir: "~> 1.11",
      deps: deps() ++ dev_deps(Mix.env()),
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
      consolidate_protocols: Mix.env() != :test
    ]
  end

  def cli do
    [
      preferred_envs: [
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
  defp elixirc_paths(_other), do: ["lib"]

  defp compilers(:test), do: Mix.compilers()
  defp compilers(_other), do: Mix.compilers()

  defp dialyzer,
    do: [
      plt_add_apps: [:mix, :gettext, :phoenix_live_view],
      ignore_warnings: ".dialyzer_ignore.exs"
    ]

  # Run "mix help deps" to learn about dependencies.
  # We split the dependencies for clarity.
  # Optional = when projects includes it, force a version match.
  # Runtime = if the app should be started by the supervisor.

  defp deps do
    [
      {:phoenix, "~> 1.7", optional: true},
      {:gettext, "~> 0.26 or ~> 1.0", optional: true},
      {:phoenix_view, "~> 2.0", optional: true},
      {:phoenix_live_view, "~> 0.18 or ~> 1.0", optional: true},
      {:phoenix_html_helpers, "~> 1.0", optional: true}
    ]
  end

  defp dev_deps(env) when env in [:test, :dev] do
    [
      {:ex_doc, "~> 0.37", only: [:dev, :test], runtime: false},
      {:credo, git: "https://github.com/rrrene/credo/", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:makeup_diff, "~> 0.1", only: [:dev], runtime: false},
      {:git_ops, "~> 2.6", only: [:dev], runtime: false},
      {:benchee, "~> 1.0", only: [:dev], runtime: false},
      {:igniter, "~> 0.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp dev_deps(_env), do: []

  defp package do
    [
      maintainers: ["Bart Otten"],
      licenses: ["MIT"],
      files:
        ~w(lib .formatter.exs mix.exs docs README.md LICENSE.md CHANGELOG.md CONTRIBUTING.md USAGE.md),
      links: %{
        Changelog: "https://hexdocs.pm/routex/changelog.html",
        GitHub: "https://github.com/BartOtten/routex",
        "Online Demo": "https://routex.fly.dev/",
        "Guide: Localize Phoenix": "https://hexdocs.pm/routex/localize_phoenix.html"
      }
    ]
  end

  defp description() do
    "Powerful Phoenix extensions: localize, customize, and innovate"
  end

  defp docs do
    [
      main: "readme",
      logo: "assets/logo.png",
      source_ref: "v#{@version}",
      source_url: @source_url,
      assets: %{"assets" => "assets"},
      before_closing_head_tag: &docs_before_closing_head_tag/1,
      extras: [
        "README.md": [title: "Overview"],
        "docs/EXTENSIONS.md": [title: "Included extensions"],
        "RELEASE_NOTES.md": [title: "Release Notes"],
        "USAGE.md": [title: "Getting started"],
        "docs/ROUTEX_AND_PHOENIX_ROUTER.md": [title: "Routex and Phoenix Router"],
        "docs/HISTORY_OF_ROUTEX.md": [title: "History of Routex"],
        "docs/EXTENSION_DEVELOPMENT.md": [title: "Extensions"],
        "docs/COMPARISON.md": [title: "Routing solutions compared"],
        "CHANGELOG.md": [title: "Changelog"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "docs/TROUBLESHOOTING.md": [title: "Troubleshooting"],
        "docs/guides/LOCALIZE_PHOENIX.md": [title: "Localize Phoenix"],
        "docs/guides/LOCALIZATION_VS_TRANSLATION.md": [title: "Localization vs Translation"]
      ],
      groups_for_extras: [
        "The project": ["README.md", "docs/EXTENSIONS.md", "RELEASE_NOTES.md", "CHANGELOG.md"],
        Guides: ["USAGE.md"] ++ Path.wildcard("docs/guides/*.md"),
        Extra: [
          "docs/ROUTEX_AND_PHOENIX_ROUTER.md",
          "docs/HISTORY_OF_ROUTEX.md",
          "docs/COMPARISON.md"
        ],
        Development: [
          "docs/EXTENSION_DEVELOPMENT.md",
          "CONTRIBUTING.md",
          "docs/TROUBLESHOOTING.md"
        ]
      ],
      filter_modules: ~r"Elixir.Routex.*$",
      groups_for_modules: [
        Routex: ~r"Routex\.?[^.]*$",
        Extensions:
          ~r/Routex\.Extension(?:\.[^.]+)?(?:\.Localize(?:\.Phoenix(?:\.Runtime|\.Routes)?)?)?$/,
        Submodules: ~r"Routex.Extension\..*\.*$"
      ],
      nest_modules_by_prefix: [
        Routex.Extension.Alternatives,
        Routex.Extension
      ],
      skip_undefined_reference_warnings_on: [
        "Routex.Attrs",
        "Routex.Extension",
        "Routex.Extension.LiveViewHooks",
        "Routex.Extension.Plugs",
        "Routex.Extension.RouteHelpers",
        "Routex.Processing",
        "Routex.Route",
        "Routex.Types"
      ],
      skip_code_autolink_to: ["Phoenix.Router.Route"]
    ]
  end

  defp copy_assets(_opts) do
    File.cp_r("assets", "doc/assets")
  end

  defp docs_before_closing_head_tag(:html) do
    ~s|
    <link rel="stylesheet" href="assets/doc.css">

    |
  end

  defp docs_before_closing_head_tag(_other), do: ""
end
