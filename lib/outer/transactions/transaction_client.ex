defmodule Outer.Transactions.TransactionClient do
  require Logger

  def ensure_wallet_balance(wallet = %{balance: nil}), do: fetch_wallet_balance(wallet)
  def ensure_wallet_balance(wallet), do: wallet

  defp fetch_wallet_balance(wallet) do
    fake_remote_call(wallet)
    balance = round(100 + :rand.uniform() * 50)
    wallet = Map.put(wallet, :balance, balance)
    Logger.debug("fetched balance for wallet #{wallet.auth_token} (balance: #{balance})")
    wallet
  end

  def make_transaction(wallet, transaction) do
    fake_remote_call(wallet)
    wallet = Map.update!(wallet, :balance, &(&1 - transaction.amount))

    Logger.debug(
      "made transaction for wallet #{wallet.auth_token} and amount #{transaction.amount} (balance: #{wallet.balance})"
    )

    wallet
  end

  def ensure_wallet_funds(wallet = %{balance: balance}, amount) when balance < amount,
    do: top_up_wallet(wallet, amount * 5)

  def ensure_wallet_funds(wallet, _amount), do: wallet

  def top_up_wallet(wallet, amount) do
    fake_remote_call(wallet)
    wallet = Map.update!(wallet, :balance, &(&1 + amount))

    Logger.debug(
      "topped up wallet #{wallet.auth_token} for #{amount} (balance: #{wallet.balance})"
    )

    wallet
  end

  defp fake_remote_call(_wallet) do
    (20 + :rand.uniform() * 10)
    |> round()
    |> Process.sleep()
  end
end
