defmodule Potcu.Listener do
  use Nostrum.Consumer
  alias Nostrum.Api
  require Logger

  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    if Nostrum.Cache.Me.get().id != msg.author.id do
      case Potcu.Utils.parse_command(msg.content) do
        :none -> :ignore
        cmd -> GenServer.call(Potcu.Bot, {msg, cmd})
      end
    end
  end

  def handle_event(event) do
    :noop
  end

end
