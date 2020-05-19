defmodule Potcu.Application do
  use Application

  def start(_type, _args) do
    children = [
      Potcu.Bot,
      Potcu.Listener,
      Potcu.Voice.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Potcu.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
