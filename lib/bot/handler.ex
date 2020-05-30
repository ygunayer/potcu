defmodule Potcu.Bot.Handler do
  use GenServer
  require Logger

  alias Nostrum.Api
  alias Nostrum.Cache
  alias Potcu.Bot.Registry
  alias Potcu.Bot.Structs.{StateData, BombStatus, VoiceStatus}
  alias Potcu.Bot.Voice.Structs.SessionInfo

  @help_text "potcu help text"

  ##################
  ## Initialization
  ##################
  def child_spec(guild_id, opts) do
    %{
      id: "bot-handler-#{guild_id}",
      start: {__MODULE__, :start_link, [guild_id, opts]}
    }
  end

  def start_link(guild_id, opts) do
    GenServer.start_link(__MODULE__, guild_id, opts)
  end

  def init(guild_id) do
    state = %StateData{
      guild_id: guild_id,
      bomb: %BombStatus{status: :idle},
      voice: %VoiceStatus{status: :not_connected}
    }
    {:ok, state}
  end

  ##################
  ## Public API
  ##################

  ##################
  ## Private API
  ##################

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
    {:ok, _} = Registry.create_voice_session(session)
    voice_state = %VoiceStatus{
      status: :connecting,
      channel_id: channel_id,
      server: server,
      session_id: session_id
    }
    %StateData{state | voice: voice_state}
  end

  defp finalize_voice_connection_attempt!(state), do: state

  ##################
  ## Callbacks
  ##################

  ## Cast
  ##########

  def handle_cast({:go_to_sender, msg}, state) do
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
  def handle_cast({:help, msg}, state) do
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

  def handle_cast({:voice_connected, _}, state = %{voice: voice = %{status: :connecting}}) do
    new_voice_state = %VoiceStatus{voice | status: :connected}
    new_state = %StateData{state | voice: new_voice_state}
    Logger.debug("Voice connection is successful")
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
