defmodule Enkiro.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EnkiroWeb.Telemetry,
      Enkiro.Repo,
      {DNSCluster, query: Application.get_env(:enkiro, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Enkiro.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Enkiro.Finch},
      # Start a worker by calling: Enkiro.Worker.start_link(arg)
      # {Enkiro.Worker, arg},
      # Start to serve requests, typically the last entry
      EnkiroWeb.Endpoint,
      # 1 hour
      {Guardian.DB.Sweeper, [interval: 60 * 60 * 1000]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Enkiro.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EnkiroWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
