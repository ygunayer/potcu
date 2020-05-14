defmodule Potcu.Bot do
  use GenServer

  def init(arg) do
    {:ok, arg}
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, {:idle}, name: Potcu.Bot)
  end

  # has the bot stop playing whatever it's playing and leave the voice channel that it's currently in
  def handle_call({msg, {:kick}}, _sender, {:bombing, _, _}) do
    Nostrum.Api.update_voice_state(msg.guild_id, nil)
    {:reply, :ignore, {:idle}}
  end

  # has the bot cancel its count down and return to its old state
  def handle_call({msg, {:kick}}, _sender, {:counting_down, _, old_state, timer}) do
    Nostrum.Api.create_message(msg.channel_id, "<poof!>")
    :timer.cancel(timer)
    {:reply, :ignore, old_state}
  end

  # has the bot begin counting down before it joins a voice channel and play the given URL
  def handle_call({msg, {:bomb, channel_id, url}}, _sender, state) do
    :erlang.send(self(), {:count_down, 3})
    {:reply, :ignore, {:counting_down, {msg, channel_id, url}, state, nil}}
  end

  # has the bot begin counting down before it joins a voice channel and play the given URL
  def handle_call({msg, {:bomb, url}}, _sender, state) do
    Nostrum.Api.create_message(msg.channel_id, "nostrum sucks")
    {:reply, :ignore, state}
    #:erlang.send(self(), {:count_down, 3})
    #{:reply, :ignore, {:counting_down, {msg, channel_id, url}, state, nil}}
  end

  # has the bot display help text
  def handle_call({msg, {:help}}, _sender, state) do
    result = Nostrum.Api.create_message(msg.channel_id, "!potcu help text")
    {:reply, result, state}
  end

  def handle_call(_msg, _sender, state) do
    {:reply, :ignore, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info({:count_down, 0}, {:counting_down, {msg, channel_id, url}, _old_state, _timer}) do
    Nostrum.Api.update_voice_state(msg.guild_id, channel_id)
    {:noreply, {:bombing, channel_id, url}}
  end

  def handle_info({:count_down, x}, {:counting_down, {msg, channel_id, url}, old_state, _timer}) do
    Nostrum.Api.create_message(msg.channel_id, "#{x}")
    timer = Process.send_after(self(), {:count_down, x - 1}, 1_000)
    {:noreply, {:counting_down, {msg, channel_id, url}, old_state, timer}}
  end

  def handle_info(_msg, state) do {:noreply, state} end

end
