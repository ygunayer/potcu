defmodule Potcu.Listener do
  use Nostrum.Consumer
  require Logger

  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def relay(command, msg) do
    case Potcu.Bot.Registry.get_handler(msg.guild_id) do
      {:ok, pid} -> GenServer.cast(pid, {command, msg})
      _ -> Logger.debug("No bot found for #{msg.guild_id}")
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    if Nostrum.Cache.Me.get().id != msg.author.id do
      case Potcu.Utils.parse_command(msg.content) do
        :none -> :ignore
        cmd ->
          Logger.info("Received command #{inspect cmd}, relaying to bot")
          relay(cmd, msg)
      end
    end
    :ignore
  end

  def handle_event({:VOICE_STATE_UPDATE, msg, _ws_state}) do
    if Nostrum.Cache.Me.get().id == msg.user_id do
      relay(:update_voice_state, msg)
    end
    :ignore
  end

  def handle_event({:VOICE_SERVER_UPDATE, msg, _ws_state}) do
    relay(:update_voice_server, msg)
    :ignore
  end

  def handle_event({:GUILD_AVAILABLE, {guild}, _ws_state}) do
    Potcu.Bot.Registry.create_handler!(guild.id)
    :ignore
  end

  def handle_event(_event) do
    :noop
  end

end
