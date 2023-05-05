import Config

config :git_ops,
  mix_project: Mix.Project.get!(),
  changelog_file: "CHANGELOG.md",
  repository_url: "https://github.com/BartOtten/routex",
  types: [
    tidbit: [
      hidden?: true
    ],
    important: [
      header: "Important Changes"
    ]
  ],
  manage_mix_version?: true,
  manage_readme_version: "USAGE.md",
  version_tag_prefix: "v"
