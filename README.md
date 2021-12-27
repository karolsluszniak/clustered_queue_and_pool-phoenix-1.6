# Phoenix 1.6 example app with clustered queue and pool

Sponsored by [Hawku](https://hawku.com).

## Features

This app builds on top of [Phoenix 1.6 example app with live auth and avatars](https://github.com/karolsluszniak/live_auth_and_avatars-phoenix-1.6) to play with clustering and specifically  with distributed Erlang/Elixir, Oban and libcluster to implement the following features:

  * **Persistent & clustered transaction queue backed by Oban** - each transaction added to the queue is persisted to PostgreSQL database with ACID guarantees and the queue is drained across the entire cluster, all thanks to Oban
  * **Clustered wallet pool** - wallets are divided equally between all nodes in the cluster, with each node maintaining a process pool for its set of wallets and adjusting the Oban transactions queue for concurrency allowing to use all wallets
  * **Ready-to-go clustering-enabled Fly deployment** - including all the config required for app to build the production image, deploy it to Fly, connect the cluster using Fly private networking and use IPv6 for endpoint and database as required

Follow the commit history to see how each was implemented.

## Usage

To start the server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

To start with local clustering:

  * Start node `a` with `PORT=4000 SERVER=1 iex --sname a -S mix`
  * Start node `b` with `PORT=4001 SERVER=1 iex --sname b -S mix`

To deploy to fly

  * Create your own app with `fly apps create someapp`
  * Fill the name in `fly.toml` as `app = someapp`
  * Ensure PostgreSQL is there with `fly postgres create` and `fly postgres attach`
  * Deploy with `fly deploy` and visit your app at [someapp.fly.dev](https://someapp.fly.dev)
  * Increase and decrease the node count with `fly scale count N` and observe the transactions page

Now you can visit [`localhost:4000`](http://localhost:4000) or [`localhost:4001`](http://localhost:4001) from your browser.
