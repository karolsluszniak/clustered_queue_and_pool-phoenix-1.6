defmodule Outer.Transactions do
  alias __MODULE__.Queue

  def make_transaction(transaction) do
    Queue.make_transaction(transaction)
  end

  def get_queue_state do
    Queue.get_state()
  end
end
