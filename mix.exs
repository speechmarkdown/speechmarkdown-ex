defmodule SpeechMarkdown.Mixfile do
  use Mix.Project

  def project do
    [
      app: :speechmarkdown,
      name: "SpeechMarkdown",
      version: File.read!("VERSION"),
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
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [extras: ["README.md"]]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.5 or ~> 1.0"},
      {:excoveralls, "~> 0.11", only: :test},
      {:credo, "~> 1.1", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  def application do
    [
      extra_applications: [:xmerl]
    ]
  end

  defp package do
    [
      files: ["mix.exs", "README.md", "VERSION", "lib"],
      maintainers: ["Brent M. Spell", "Arjan Scherpenisse"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/speechmarkdown/speechmarkdown-ex",
        "Docs" => "http://hexdocs.pm/speechmarkdown/"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp ensure_submodule(_) do
    path =
      Path.join(__DIR__, "test/fixtures/speechmarkdown-test-files/test-data")

    if not File.dir?(path) do
      :os.cmd('git submodule update --init')
    end
  end

  defp aliases do
    [
      test: [&ensure_submodule/1, "test"]
    ]
  end
end
