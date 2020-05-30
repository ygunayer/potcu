defmodule Potcu.Bot.Voice.Session do
  use GenServer
  require Logger

  alias Potcu.Bot.Voice.Structs.{WSState, StateData, Payload, DiscordHeartbeat, DiscordVoiceInfo}

  @timeout_connect 10_000
  @timeout_upgrade 10_000

  ##################
  ## Initialization
  ##################
  def child_spec(session, opts) do
    %{
      id: "bot-voice-session-#{session.guild_id}",
      start: {__MODULE__, :start_link, [session, opts]}
    }
  end

  def start_link(session, opts) do
    GenServer.start_link(__MODULE__, session, opts)
  end

  def init(session) do
    state_data = %StateData{
      session: session,
      ws: %WSState{conn: nil, stream: nil},
      udp: nil,
      heartbeat: nil,
      voice: nil
    }
    {:ok, {:connecting, state_data}, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    reconnect(state)
  end

  ##################
  ## Private API
  ##################

  defp reconnect({_, data}) do
    %{token: token, endpoint: endpoint, guild_id: guild_id, session_id: session_id, user_id: user_id} = data.session
    auth = fn conn ->
      stream = :gun.ws_upgrade(conn, "/?v=4")
      receive do
        {:gun_upgrade, ^conn, ^stream, [<<"websocket">>], _headers} -> {:ok, stream}
        other -> other
      after
        @timeout_upgrade -> {:error, :timeout}
      end
    end

    hostname = String.replace(endpoint, ~r/\:\d+/, "")
    Logger.debug("Connecting to voice server at #{hostname}")
    with {:ok, conn} <- :gun.open(:binary.bin_to_list(hostname), 443, %{protocols: [:http], transport: :tls}),
      {:ok, :http} <- :gun.await_up(conn, @timeout_connect),
      {:ok, stream} <- auth.(conn),

      {:ok, payload_identify} <- Payload.identify(user_id, token, guild_id, session_id),
      _ <- :gun.ws_send(conn, {:text, payload_identify})
    do
      new_data = %StateData{data | ws: %WSState{conn: conn, stream: stream}}
      Logger.debug("Voice server connection established, identifying...")
      {:noreply, {:identifying, new_data}}
    else
      error ->
        Logger.error("Failed to connect to the voice server at #{hostname} due to #{inspect error}")
        exit(error)
    end
  end

  defp disconnect({_, %{ws: ws, udp: udp}}) do
    if ws != nil do
      :gun.close(ws)
    end

    if udp != nil do
      :gen_udp.close(udp)
    end
  end

  ##################
  ## Callbacks
  ##################

  ## Cast
  ##########

  def handle_cast({:ws_payload, %{"op" => :ready, "d" => payload}}, {:identifying, state_data}) do
    case DiscordVoiceInfo.from(payload) do
      {:ok, voice_info} ->
        Logger.debug("Connected to voice server")
        Potcu.Bot.Registry.cast(:handler, state_data.session.guild_id, {:voice_connected, self()})
        # TODO: establish UDP connection
        new_state_data = %StateData{state_data | voice: voice_info}
        {:noreply, {:connected, new_state_data}}
      error ->
        Logger.error("Failed to identify voice info due to #{inspect error}")
        exit(error)
    end
  end

  def handle_cast({:ws_payload, %{"op" => :hello, "d" => %{"heartbeat_interval" => heartbeat_interval}}}, state) do
    interval = Kernel.trunc(heartbeat_interval)
    send(self(), {:heartbeat_tick, interval})
    {:noreply, state}
  end

  def handle_cast({:ws_payload, %{"op" => :heartbeat_ack}}, state) do
    Logger.debug("Voice heartbeat ACK")
    {:noreply, state}
  end

  def handle_cast({:ws_payload, %{"op" => :client_disconnect}}, _) do
    Logger.debug("Disconnected from voice server")
    exit(:client_disconnect)
  end

  def handle_cast({:ws_payload, payload}, state) do
    Logger.debug("Unrecognized WS payload #{inspect payload}")
    {:noreply, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  ## Call
  ##########

  def handle_call(:identify, sender, state) do
    identity = state.session.guild_id
    send(sender, {:identity, identity, self()})
    {:reply, identity, state}
  end

  def handle_call(_msg, _sender, state) do
    {:reply, :ignore, state}
  end

  ## Info
  ##########

  def handle_info({:disconnect}, state) do
    Logger.debug("Shutting down voice session")
    disconnect(state)
    exit(:normal)
  end

  def handle_info({:heartbeat_tick, interval}, state = {name, state_data}) do
    with {:ok, payload} <- Payload.heartbeat(),
      :ok <- :gun.ws_send(state_data.ws.conn, {:text, payload})
    do
      if state_data.heartbeat != nil do
        Process.cancel_timer(state_data.heartbeat.timer)
      end
      timer = Process.send_after(self(), {:heartbeat_tick, interval}, interval)
      heartbeat = %DiscordHeartbeat{interval: interval, timer: timer}
      new_state_data = %StateData{state_data | heartbeat: heartbeat}
      {:noreply, {name, new_state_data}}
    else
      error ->
        Logger.warn("Failed to send heartbeat #{inspect error}")
        {:noreply, state}
    end
  end

  def handle_info({:gun_ws, _conn, _stream, {:close, errno, reason}}, _) do
    Logger.warn("Disconnected from voice server due to #{inspect reason} (errno #{errno})")
    exit(reason)
  end

  def handle_info({:gun_ws, _worker, _stream, frame}, state) do
    case Payload.parse(frame) do
      {:ok, payload} -> GenServer.cast(self(), {:ws_payload, payload})
      error -> Logger.warn("Failed to parse WS frame due to #{inspect error}")
    end
    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

end
