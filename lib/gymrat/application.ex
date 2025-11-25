defmodule Gymrat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GymratWeb.Telemetry,
      Gymrat.Repo,
      {DNSCluster, query: Application.get_env(:gymrat, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:gymrat, Oban)},
      {Phoenix.PubSub, name: Gymrat.PubSub},
      # Start a worker by calling: Gymrat.Worker.start_link(arg)
      # {Gymrat.Worker, arg},
      # Start to serve requests, typically the last entry
      GymratWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gymrat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GymratWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
