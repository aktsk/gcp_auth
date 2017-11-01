defmodule GCPAuth.Mixfile do
  use Mix.Project

  def project do
    [app: :gcp_auth,
     version: "0.1.0",
     elixir: "~> 1.3",
     elixirc_options: [warnings_as_errors: true],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "GCP (Google Cloud Platform) auth library using Application Default Credentials.",
     deps: deps(),
     package: package()]
  end

  def application do
    [applications: [:httpoison, :json_web_token, :logger],
     mod: {GCPAuth, []}]
  end

  defp deps do
    [{:httpoison, "~> 0.11.1"},
     {:json_web_token, "~> 0.2.10"},
     {:credo, "~> 0.4.6", only: :dev}]
  end

  defp package do
    [maintainers: ["Seizan Shimazaki"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/aktsk/gcp_auth"},
     files: ~w(mix.exs README.md LICENSE lib)]
  end
end
