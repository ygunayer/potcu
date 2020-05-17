use Mix.Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug

config :nostrum,
  token: "your token here",
  shards: :auto

import_config "#{Mix.env()}.exs"
