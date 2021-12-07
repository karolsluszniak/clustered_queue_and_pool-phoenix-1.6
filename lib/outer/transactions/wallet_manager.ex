defmodule Outer.Transactions.WalletManager do
  use GenServer
  require Logger
  alias Outer.Transactions.Wallet

  def start_link(opts) do
    Logger.debug("queue starting with #{inspect(opts)}")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def make_transaction(transaction) do
    GenServer.call(__MODULE__, {:make_transaction, transaction}, :infinity)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def init(opts) do
    state =
      %{
        wallet_auth_tokens: opts[:wallet_auth_tokens],
        wallets: [],
        pending_transactions: []
      }
      |> sync_wallet_workers()

    :net_kernel.monitor_nodes(true)

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:make_transaction, transaction}, from, state = %{wallets: wallets}) do
    state =
      case claim_wallet(wallets) do
        {:ok, {pid, _wallet}, wallets} ->
          GenServer.cast(pid, {:make_transaction, transaction, from})
          Map.put(state, :wallets, wallets)

        :error ->
          Map.update!(state, :pending_transactions, &(&1 ++ [{transaction, from}]))
      end

    {:noreply, state}
  end

  @impl true
  def handle_info({:release_wallet, pid, wallet}, state = %{wallets: wallets}) do
    wallets = List.keyreplace(wallets, pid, 0, {pid, wallet, false})
    state = Map.put(state, :wallets, wallets)
    {:noreply, make_next_pending_transaction(state)}
  end

  @impl true
  def handle_info({node_change, _node}, state) when node_change in ~w[nodeup nodedown]a do
    {:noreply, sync_wallet_workers(state)}
  end

  # This function updates the pool of wallet workers to only have wallets designated to this
  # particular node within an Erlang cluster. It does so by chunking wallet configs among all
  # nodes, picking its own chunk and taking a look at what wallet workers are already running
  # - starting new ones or terminating old ones to achieve the final wallet pool.
  defp sync_wallet_workers(
         state = %{
           wallet_auth_tokens: configured_wallet_auth_tokens,
           wallets: already_started_wallets
         }
       ) do
    already_started_wallet_auth_tokens =
      Enum.map(already_started_wallets, fn {_, wallet, _} -> wallet.auth_token end)

    wanted_wallet_auth_tokens = get_node_chunk(configured_wallet_auth_tokens)

    if Oban.config().queues[:transactions] do
      Oban.scale_queue(
        queue: :transactions,
        limit: length(wanted_wallet_auth_tokens),
        local_only: true
      )
    end

    newly_started_wallets =
      Enum.map(wanted_wallet_auth_tokens -- already_started_wallet_auth_tokens, fn auth_token ->
        wallet = %Wallet{auth_token: auth_token}

        {:ok, pid} =
          DynamicSupervisor.start_child(
            Outer.Transactions.WalletSupervisor,
            {Outer.Transactions.WalletWorker, wallet}
          )

        {pid, wallet, false}
      end)

    {kept_wallets, wallets_pending_termination} =
      Enum.split_with(already_started_wallets, fn {_, wallet, _} ->
        Enum.member?(wanted_wallet_auth_tokens, wallet.auth_token)
      end)

    Enum.each(wallets_pending_termination, fn {pid, _, _} ->
      DynamicSupervisor.terminate_child(Outer.Transactions.WalletSupervisor, pid)
    end)

    Map.put(state, :wallets, newly_started_wallets ++ kept_wallets)
  end

  # This is where an arbitrary sortable (so that all nodes get the same deterministic result) list
  # is chunked among nodes and a chunk designated to this specific node is picked and returned.
  defp get_node_chunk(list) do
    node = Node.self()
    nodes = [node | Node.list()] |> Enum.sort()
    node_index = Enum.find_index(nodes, &(&1 == node))
    node_max_count = ceil(length(list) / length(nodes))
    lists_per_node = list |> Enum.to_list() |> Enum.chunk_every(node_max_count)

    Enum.at(lists_per_node, node_index) || []
  end

  defp make_next_pending_transaction(state = %{pending_transactions: []}) do
    state
  end

  defp make_next_pending_transaction(
         state = %{
           pending_transactions: [{transaction, from} | remaining_transactions],
           wallets: wallets
         }
       ) do
    case claim_wallet(wallets) do
      {:ok, {pid, _wallet}, wallets} ->
        GenServer.cast(pid, {:make_transaction, transaction, from})

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
