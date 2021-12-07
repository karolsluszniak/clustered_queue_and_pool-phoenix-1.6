defmodule Outer.Transactions do
  alias __MODULE__.{WalletManager, TransactionWorker}

  def enqueue_transaction(transaction) do
    %{amount: transaction.amount}
    |> TransactionWorker.new()
    |> Oban.insert()
  end

  def get_wallet_manager_state do
    WalletManager.get_state()
  end

  def get_transaction_queue_stats do
    import Ecto.Query

    result =
      Oban.Repo.all(
        Oban.config(),
        Oban.Job
        |> where([j], j.worker == "Outer.Transactions.TransactionWorker")
        |> group_by([j], [j.state])
        |> select([j], {j.state, count(j.id)})
      )
      |> Map.new()

    %{
      pending: result["available"] || 0,
      executing: result["executing"] || 0,
      completed: result["completed"] || 0
    }
  end
end
