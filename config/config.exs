# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :potcu,
  ecto_repos: [Potcu.Repo]

# Configures the endpoint
config :potcu, PotcuWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JiIdPqrpHL4WtpwDbGp0ISb7vLkZMaQXc0RD8CSTgBUqlbgt9NXUC4l2IjsVAh9Y",
  render_errors: [view: PotcuWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Potcu.PubSub,
  live_view: [signing_salt: "NBdMEbI3"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :nostrum,
  token: "<<your token here>>",
  num_shards: 1

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
