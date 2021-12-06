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
end
