defmodule Potcu.Bot do
  use GenServer

  @help_text "potcu help text"

  ##################
  ## Initialization
  ##################
  def init(arg) do
    {:ok, arg}
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, {:idle}, name: Potcu.Bot)
  end

  ##################
  ## Private API
  ##################
  def leave_channel(msg) do
    Nostrum.Api.update_voice_state(msg.guild_id, nil)
  end

  def cancel_countdown(msg) do
    leave_channel(msg)
    #Nostrum.Api.create_message(msg.channel_id, "*Fizzle...*")
  end

  def join_channel(msg, channel_id) do
    cancel_countdown(msg)
    leave_channel(msg)
    Nostrum.Api.update_voice_state(msg.guild_id, channel_id)
  end

  def begin_countdown(_msg, seconds \\ 3) do
    send(self(), {:count_down, seconds})
  end

  def send_message_to(channel_id, content) do
    Nostrum.Api.create_message(channel_id, content)
  end

  def reply(msg, content) do
    send_message_to(msg.channel_id, content)
  end

  def play_url(url) do
    IO.puts("Now playing #{url}")
  end

  def go_to_sender(msg) do
    with {:ok, guild} <- Nostrum.Cache.GuildCache.get(msg.guild_id),
      voice_state when voice_state != nil <- Map.get(guild.voice_states, msg.author.id)
    do
      join_channel(msg, voice_state.channel_id)
      reply(msg, "geldim abi")
    else
      nil -> reply(msg, "abi nerdesin bulamadim ya")
      error -> reply(msg, "gelemedim aq #{inspect error}")
    end
  end

  ##################
  ## Callbacks
  ##################

  ## Cast
  ##########

  # has the bot cancel its count down and return to its old state
  def handle_cast({msg, {:kick}}, {:counting_down, _, old_state, timer}) do
    cancel_countdown(msg)
    :timer.cancel(timer)
    {:noreply, old_state}
  end

  # has the bot stop playing whatever it's playing and leave the voice channel that it's currently in
  def handle_cast({msg, {:kick}}, _state) do
    cancel_countdown(msg)
    {:noreply, {:idle}}
  end

  # has the bot begin counting down before it joins a voice channel and play the given URL
  def handle_cast({msg, {:bomb, channel_id, url}}, state) do
    begin_countdown(msg)
    {:noreply, {:counting_down, {msg, channel_id, url}, state, nil}}
  end

  # has the bot begin counting down before it joins a voice channel and play the given URL
  def handle_cast({msg, {:go_to_sender}}, _state) do
    go_to_sender(msg)
    {:noreply, {:idle}}
  end

  # has the bot begin counting down before it joins a voice channel and play the given URL
  def handle_cast({msg, {:bomb, url}}, state) do
    begin_countdown(msg)
    {:noreply, {:counting_down, {msg, msg.channel_id, url}, state, nil}}
  end

  # has the bot display help text
  def handle_cast({msg, {:help}}, state) do
    reply(msg, @help_text)
    {:noreply, state}
  end

  def handle_cast(msg, state) do
    IO.puts("GOT UKNOWN #{inspect msg} IN #{inspect state}")
    {:noreply, state}
  end

  ## Info
  ##########

  # has the bot play the given URL
  def handle_info({:count_down, 0}, {:counting_down, {_, channel_id, url}, _old_state, _timer}) do
    play_url(url)
    {:noreply, {:bombing, channel_id, url}}
  end

  def handle_info({:count_down, x}, {:counting_down, {msg, channel_id, url}, old_state, _timer}) do
    reply(msg, "#{x}")
    timer = Process.send_after(Potcu.Bot, {:count_down, x - 1}, 1_000)
    {:noreply, {:counting_down, {msg, channel_id, url}, old_state, timer}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  ## Call
  ##########

  def handle_call(_msg, _sender, state) do
    {:reply, :ignore, state}
  end

end
