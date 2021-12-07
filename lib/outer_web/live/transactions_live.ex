defmodule OuterWeb.TransactionsLive do
  use OuterWeb, :live_controller
  alias Outer.{Transactions, Transactions.Transaction}

  @action_handler true
  def index(socket, _params) do
    do_update_queue_state(socket)
  end

  @message_handler true
  def update_queue_state(socket, _payload) do
    do_update_queue_state(socket)
  end

  defp do_update_queue_state(socket) do
    Process.send_after(self(), :update_queue_state, 100)

    wallet_manager_state = Transactions.get_wallet_manager_state()
    all_wallet_count = length(wallet_manager_state.wallet_auth_tokens)
    node_wallet_count = length(wallet_manager_state.wallets)
    occupied_wallet_count = wallet_manager_state.wallets |> Enum.filter(&elem(&1, 2)) |> length()
    manager_pending_transaction_count = length(wallet_manager_state.pending_transactions)

    transaction_queue_stats = Transactions.get_transaction_queue_stats()

    assign(socket,
      all_wallet_count: all_wallet_count,
      node_wallet_count: node_wallet_count,
      occupied_wallet_count: occupied_wallet_count,
      manager_pending_transaction_count: manager_pending_transaction_count,
      queue_pending_transaction_count: transaction_queue_stats.pending,
      queue_executing_transaction_count: transaction_queue_stats.executing,
      queue_completed_transaction_count: transaction_queue_stats.completed
    )
  end

  @event_handler true
  def enqueue(socket, %{
        "operation" => %{"amount" => amount, "transaction_count" => transaction_count}
      }) do
    amount = String.to_integer(amount)
    transaction_count = String.to_integer(transaction_count)

    for _ <- 1..transaction_count do
      Transactions.enqueue_transaction(%Transaction{amount: amount})
    end

    socket
  end
end
