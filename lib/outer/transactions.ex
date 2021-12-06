defmodule Outer.Transactions do
  alias __MODULE__.TransactionWorker

  def enqueue_transaction(transaction) do
    %{amount: transaction.amount}
    |> TransactionWorker.new()
    |> Oban.insert()
  end
end
