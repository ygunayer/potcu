defmodule Potcu.Voice.Session do
  use GenServer

  defmodule State do
    defstruct [
      :token,
      :guild_id,
      :user_id,
      :session_id,
      :conn
    ]
  end

  def start_link(token, guild_id, user_id) do
    GenServer.start_link(__MODULE__, [token, guild_id, user_id])
  end

  def init(token, guild_id, user_id) do
    state = %State{
      token: token,
      guild_id: guild_id,
      user_id: user_id,
      conn: nil
    }
    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    {:ok, conn} = :gun.open("gateway.discord.gg", 80)
  end

end
