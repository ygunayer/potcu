defmodule PotcuConsumers.Bot do
  use Nostrum.Consumer
  alias Nostrum.Api
  require Logger

  def start_link() do
    Logger.info("potcu bot has started")
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case msg.content do
      "!potcu" ->
        Api.create_message!(msg.channel_id, "sa #{msg.author.username}")
      _ ->
        :ignore
    end
  end

  def handle_event(event) do
    :noop
  end

end
