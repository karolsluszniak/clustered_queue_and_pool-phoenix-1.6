defmodule Outer.Transactions.TransactionWorker do
  use Oban.Worker, queue: :transactions
  alias Outer.Transactions.{WalletManager, Transaction}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"amount" => amount}}) do
    transaction = %Transaction{amount: amount}
    WalletManager.make_transaction(transaction)
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(60)
end
