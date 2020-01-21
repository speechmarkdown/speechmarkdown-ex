defmodule SpeechMarkdown.Mixfile do
  use Mix.Project

  def project do
    [
      app: :speechmarkdown,
      name: "SpeechMarkdown",
      version: "0.1.0",
      elixir: "~> 1.9",
      description: "SpeechMarkdown transpiler for Elixir",
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.post": :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzerignore",
        plt_add_deps: :transitive
      ],
      docs: [extras: ["README.md"]]
    ]
  end

  defp deps do
    [
      {:sweet_xml, "~> 0.6"},
      {:nimble_parsec, "~> 0.5", optional: true},
      {:excoveralls, "~> 0.11", only: :test},
      {:credo, "~> 1.1", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["mix.exs", "README.md", "lib"],
      maintainers: ["Brent M. Spell"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/spokestack/speechmarkdown-ex",
        "Docs" => "http://hexdocs.pm/speechmarkdown/"
      }
    ]
  end
end
