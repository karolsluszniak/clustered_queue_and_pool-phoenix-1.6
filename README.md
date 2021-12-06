# Outer

To start the server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

To start with S3 uploads enabled:

  * Authorize with `export AWS_ACCESS_KEY_ID= AWS_SECRET_ACCESS_KEY= AWS_S3_BUCKET=`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

To start with local clustering:

  * Start node `a` with `PORT=4000 SERVER=1 iex --sname a -S mix`
  * Start node `b` with `PORT=4001 SERVER=1 iex --sname b -S mix`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
