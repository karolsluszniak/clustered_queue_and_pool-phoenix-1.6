defmodule Outer.Transactions.Queue do
  use GenServer
  require Logger
  alias Outer.Transactions.Wallet

  def start_link(opts) do
    Logger.debug("queue starting with #{inspect(opts)}")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def make_transaction(transaction) do
    GenServer.cast(__MODULE__, {:make_transaction, transaction})
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def init(opts) do
    wallets =
      Enum.map(opts[:wallet_auth_tokens], fn auth_token ->
        wallet = %Wallet{auth_token: auth_token}

        {:ok, pid} =
          DynamicSupervisor.start_child(
            Outer.Transactions.WalletSupervisor,
            {Outer.Transactions.WalletWorker, wallet}
          )

        {pid, wallet, false}
      end)

    {:ok, %{wallets: wallets, pending_transactions: []}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:make_transaction, transaction}, state = %{wallets: wallets}) do
    state =
      case claim_wallet(wallets) do
        {:ok, {pid, _wallet}, wallets} ->
          GenServer.cast(pid, {:make_transaction, transaction})
          Map.put(state, :wallets, wallets)

        :error ->
          Map.update!(state, :pending_transactions, &(&1 ++ [transaction]))
      end

    {:noreply, state}
  end

  @impl true
  def handle_info({:release_wallet, pid, wallet}, state = %{wallets: wallets}) do
    wallets = List.keyreplace(wallets, pid, 0, {pid, wallet, false})
    state = Map.put(state, :wallets, wallets)
    {:noreply, make_next_pending_transaction(state)}
  end

  defp make_next_pending_transaction(state = %{pending_transactions: []}) do
    state
  end

  defp make_next_pending_transaction(
         state = %{pending_transactions: [transaction | remaining_transactions], wallets: wallets}
       ) do
    case claim_wallet(wallets) do
      {:ok, {pid, _wallet}, wallets} ->
        GenServer.cast(pid, {:make_transaction, transaction})

        state
        |> Map.put(:wallets, wallets)
        |> Map.put(:pending_transactions, remaining_transactions)

      :error ->
        state
    end
  end

  defp claim_wallet(wallets) do
    wallets
    |> Enum.shuffle()
    |> Enum.find_value(fn
      {pid, wallet, false} -> {pid, wallet}
      _ -> nil
    end)
    |> case do
      {pid, wallet} -> {:ok, {pid, wallet}, List.keyreplace(wallets, pid, 0, {pid, wallet, true})}
      nil -> :error
    end
  end
end
