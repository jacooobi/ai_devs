defmodule AiDevs.MixProject do
  use Mix.Project

  def project do
    [
      app: :ai_devs,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:floki, "~> 0.35.0"},
      {:openai_ex, "~> 0.9.13"},
      {:uuid, "~> 1.1"},
      {:boltx, "~> 0.0.6"},
      {:html2text, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:text_chunker, "~> 0.4.0"}
    ]
  end
end
