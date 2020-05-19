defmodule Potcu.Listener do
  use Nostrum.Consumer
  require Logger

  alias Potcu.Voice
  alias Nostrum.Struct.Guild.Voice.Server

  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    if Nostrum.Cache.Me.get().id != msg.author.id do
      case Potcu.Utils.parse_command(msg.content) do
        :none -> :ignore
        cmd ->
          Logger.info("Received command #{inspect cmd}, relaying to bot")
          GenServer.cast(Potcu.Bot, {msg, cmd})
      end
    end
    :ignore
  end

  def handle_event({:VOICE_STATE_UPDATE, msg, _ws_state}) do
    if Nostrum.Cache.Me.get().id == msg.user_id do
      GenServer.cast(Potcu.Bot, {:update_voice_state, msg})
    end
    :ignore
  end

  def handle_event({:VOICE_SERVER_UPDATE, msg, _ws_state}) do
    GenServer.cast(Potcu.Bot, {:update_voice_server, msg})
    :ignore
  end

  def handle_event(_event) do
    :noop
  end

end
