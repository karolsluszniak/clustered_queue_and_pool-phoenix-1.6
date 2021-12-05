defmodule OuterWeb.TransactionsLive do
  use OuterWeb, :live_controller
  alias Outer.{Transactions, Transactions.Transaction}

  @action_handler true
  def index(socket, _params) do
    Process.send_after(self(), :update_queue_state, 100)
    update_queue_state(socket)
  end

  @message_handler true
  def update_queue_state(socket, _payload) do
    Process.send_after(self(), :update_queue_state, 100)
    update_queue_state(socket)
  end

  defp update_queue_state(socket) do
    queue_state = Transactions.get_queue_state()
    wallets = queue_state.wallets

    assign(socket,
      wallets: wallets,
      pending_transactions_count: length(queue_state.pending_transactions)
    )
  end

  @event_handler true
  def enqueue(socket, %{
        "operation" => %{"amount" => amount, "transaction_count" => transaction_count}
      }) do
    amount = String.to_integer(amount)
    transaction_count = String.to_integer(transaction_count)

    for _ <- 1..transaction_count do
      Transactions.make_transaction(%Transaction{amount: amount})
    end

    socket
  end
end
