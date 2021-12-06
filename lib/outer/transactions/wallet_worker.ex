defmodule Outer.Transactions.WalletWorker do
  use GenServer
  require Logger
  alias Outer.Transactions.TransactionClient

  def start_link(wallet) do
    Logger.debug("wallet worker starting for wallet #{wallet.auth_token}")
    GenServer.start_link(__MODULE__, wallet)
  end

  @impl true
  def init(wallet) do
    Process.flag(:trap_exit, true)
    {:ok, wallet}
  end

  @impl true
  def terminate(_reason, wallet) do
    Logger.debug("wallet worker terminating for wallet #{wallet.auth_token}")
    wallet
  end

  @impl true
  def handle_cast({:make_transaction, transaction, from}, wallet) do
    wallet =
      wallet
      |> TransactionClient.ensure_wallet_balance()
      |> TransactionClient.ensure_wallet_funds(transaction.amount)
      |> TransactionClient.make_transaction(transaction)

    send(Outer.Transactions.Manager, {:release_wallet, self(), wallet})
    GenServer.reply(from, :ok)

    {:noreply, wallet}
  end
end
