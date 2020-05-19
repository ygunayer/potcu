defmodule Potcu.Bot do
  use GenServer
  require Logger

  alias Nostrum.Api
  alias Nostrum.Cache
  alias Potcu.Bot.Structs.{StateData, BombStatus, VoiceStatus}
  alias Potcu.Voice.Structs.SessionInfo

  @help_text "potcu help text"

  ##################
  ## Initialization
  ##################
  def init(arg) do
    {:ok, arg}
  end

  def start_link(_args) do
    state = %StateData{
      bomb: %BombStatus{status: :idle},
      voice: %VoiceStatus{status: :not_connected}
    }
    GenServer.start_link(__MODULE__, state, name: Potcu.Bot)
  end

  defp begin_join_voice!(state, msg, channel_id) do
    Nostrum.Api.update_voice_state(msg.guild_id, channel_id)
    voice_status = %VoiceStatus{status: :preparing, channel_id: channel_id}
    %StateData{state | voice: voice_status}
  end

  defp set_voice_session_id!(state, session_id) do
    voice_status = %VoiceStatus{state.voice | session_id: session_id}
    %StateData{state | voice: voice_status}
      |> finalize_voice_connection_attempt!()
  end

  defp set_voice_server!(state, server) do
    voice_status = %VoiceStatus{state.voice | server: server}
    %StateData{state | voice: voice_status}
      |> finalize_voice_connection_attempt!()
  end

  defp finalize_voice_connection_attempt!(state = %{voice: %{status: :preparing, session_id: session_id, server: server, channel_id: channel_id}}) when session_id != nil and server != nil do
    bot = Cache.Me.get()
    session = SessionInfo.from(bot.id, session_id, server)
    pid = Potcu.Voice.Supervisor.create_session!(session)
    voice_state = %VoiceStatus{
      status: :connecting,
      channel_id: channel_id,
      server: server,
      session_id: session_id,
      handler: pid
    }
    %StateData{state | voice: voice_state}
  end

  defp finalize_voice_connection_attempt!(state), do: state

  ##################
  ## Callbacks
  ##################

  ## Cast
  ##########

  def handle_cast({msg, {:go_to_sender}}, state) do
    guild = Nostrum.Cache.GuildCache.get!(msg.guild_id)
    voice_state = Map.get(guild.voice_states, msg.author.id)
    case voice_state do
      nil ->
        Api.create_message!(msg.channel_id, "e konusmuyon ki abi nereye gelem")
        {:noreply, state}
      _ ->
        Api.create_message!(msg.channel_id, "geliyom abi")
        new_state = state |> begin_join_voice!(msg, voice_state.channel_id)
        {:noreply, new_state}
    end
  end

  # has the bot display help text
  def handle_cast({msg, {:help}}, state) do
    Api.create_message!(msg.channel_id, @help_text)
    {:noreply, state}
  end

  # updates the Discord voice state
  def handle_cast({:update_voice_state, %{session_id: session_id}}, state) do
    new_state = set_voice_session_id!(state, session_id)
    {:noreply, new_state}
  end

  # updates the Discord voice server information
  def handle_cast({:update_voice_server, voice_server}, state) do
    new_state = set_voice_server!(state, voice_server)
    {:noreply, new_state}
  end

  def handle_cast(_, state), do: {:noreply, state}

  ## Info
  ##########

  def handle_info(_, state) do
    {:noreply, state}
  end

  ## Call
  ##########

  def handle_call(_msg, _sender, state) do
    {:reply, :ignore, state}
  end

end
