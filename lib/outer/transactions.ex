defmodule Outer.Transactions do
  alias __MODULE__.Manager

  def make_transaction(transaction) do
    Manager.make_transaction(transaction)
  end

  def get_queue_state do
    Manager.get_state()
  end
end
