# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :outer,
  ecto_repos: [Outer.Repo]

# Configures the endpoint
config :outer, OuterWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: OuterWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Outer.PubSub,
  live_view: [signing_salt: "ca9MJsVy"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :outer, Outer.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure default file uploading
config :waffle,
  storage: Waffle.Storage.Local,
  storage_dir_prefix: "priv"

config :ex_aws,
  json_codec: Jason

config :outer, Outer.Transactions, wallet_auth_tokens: 1..1000 |> Enum.map(fn i -> "w#{i}" end)

config :outer, Oban, repo: Outer.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
