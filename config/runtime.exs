import Config

# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

# Log level (may set to "debug" if needed)

if log_level = System.get_env("LOG_LEVEL") do
  config :logger, level: String.to_atom(log_level)
end

# Server (used later)

server =
  case System.fetch_env("SERVER") do
    {:ok, "1"} -> true
    {:ok, "0"} -> false
    _ -> nil
  end

# Fly (used later)

fly_app = System.get_env("FLY_APP_NAME")

# Database URL and pool size

if database_url = System.get_env("DATABASE_URL") do
  config :outer, Outer.Repo, url: database_url
end

if pool_size = System.get_env("POOL_SIZE") do
  config :outer, Outer.Repo, pool_size: String.to_integer(pool_size)
end

if fly_app do
  config :outer, Outer.Repo, socket_options: [:inet6]
end

# Endpoint

port = System.get_env("PORT")

http = []
http = if port, do: http ++ [port: String.to_integer(port)], else: http
http = if fly_app, do: http ++ [transport_options: [socket_opts: [:inet6]]], else: http

if Enum.any?(http) do
  config :outer, OuterWeb.Endpoint, http: http
end

url =
  [
    scheme: System.get_env("URL_SCHEME"),
    host: System.get_env("HOST") || (fly_app && "#{fly_app}.fly.dev"),
    port: System.get_env("URL_PORT") && String.to_integer(System.get_env("URL_PORT"))
  ]
  |> Enum.filter(&elem(&1, 1))

if url != [] do
  config :outer, OuterWeb.Endpoint, url: url
end

if secret_key_base = System.get_env("SECRET_KEY_BASE") do
  config :outer, OuterWeb.Endpoint, secret_key_base: secret_key_base
end

unless is_nil(server) do
  config :outer, OuterWeb.Endpoint, server: server && System.get_env("WEB", "1") == "1"
end

# Configure S3 uploads

aws_access_key_id = System.get_env("AWS_ACCESS_KEY_ID")
aws_secret_access_key = System.get_env("AWS_SECRET_ACCESS_KEY")
aws_s3_bucket = System.get_env("AWS_S3_BUCKET")

cond do
  aws_access_key_id && aws_secret_access_key && aws_s3_bucket ->
    aws_region = System.get_env("AWS_REGION", "us-east-1")

    config :waffle,
      storage: Waffle.Storage.S3,
      bucket: aws_s3_bucket

    config :ex_aws,
      access_key_id: aws_access_key_id,
      secret_access_key: aws_secret_access_key,
      region: aws_region

  aws_access_key_id || aws_secret_access_key || aws_s3_bucket ->
    raise """
    environment variables AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY + AWS_S3_BUCKET
    must be all set together (currently some are provided while others are missing).
    """

  ## Commented out temporarily to deploy without AWS bucket
  # config_env() == :prod ->
  #   raise """
  #   environment variables AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY + AWS_S3_BUCKET
  #   are missing (local uploads are not supported for prod).
  #   """

  true ->
    :ok
end
