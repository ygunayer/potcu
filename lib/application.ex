defmodule Potcu.Application do
  use Application

  def start(_type, _args) do
    children = [
      Potcu.Listener,
      Potcu.Bot.Registry,
    ]

    opts = [strategy: :one_for_one, name: Potcu.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
