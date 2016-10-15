defmodule GCPAuth do
  use Application

  def start(_type, _args) do
    children = case Application.get_env(:gcp_auth, :enabled) do
      false ->
        []
      _ ->
        [Supervisor.Spec.worker(GCPAuth.Token, [])]
    end
    opts = [strategy: :one_for_one, name: GCPAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
