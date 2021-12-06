defmodule Outer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    oban_config = Application.fetch_env!(:outer, Oban)
    transactions_config = Application.fetch_env!(:outer, Outer.Transactions)
    topologies = Application.fetch_env!(:libcluster, :topologies) || []

    children = [
      # Start the Ecto repository
      Outer.Repo,
      # Start the Telemetry supervisor
      OuterWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Outer.PubSub},
      # Start the Endpoint (http/https)
      OuterWeb.Endpoint,
      # Start the Transactions system
      {DynamicSupervisor, strategy: :one_for_one, name: Outer.Transactions.WalletSupervisor},
      {Outer.Transactions.WalletManager, transactions_config},
      # Start clustering
      {Cluster.Supervisor, [topologies, [name: Outer.ClusterSupervisor]]},
      # Start background jobs
      {Oban, oban_config}
      # Start a worker by calling: Outer.Worker.start_link(arg)
      # {Outer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Outer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OuterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
