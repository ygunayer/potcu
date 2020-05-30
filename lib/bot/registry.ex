defmodule Potcu.Bot.Registry do
  use Supervisor
  require Logger

  alias Potcu.Utils

  @registry_name :potcu_bot_registry


  ##################
  ## Initialization
  ##################

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      {Registry, [keys: :unique, name: @registry_name]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  ##################
  ## Private API
  ##################

  defp spec_of(:handler, guild_id) do
    name = {:via, Registry, {@registry_name, {:handler, guild_id}}}
    Potcu.Bot.Handler.child_spec(guild_id, name: name)
  end

  defp spec_of(:voice_session, session) do
    name = {:via, Registry, {@registry_name, {:voice_session, session.guild_id}}}
    Potcu.Bot.Voice.Session.child_spec(session, name: name)
  end

  defp lookup(name) do
    case Registry.lookup(@registry_name, name) do
      [{pid, _}] -> {:ok, pid}
      _ -> nil
    end
  end

  ##################
  ## Public API
  ##################

  def cast(:handler, guild_id, msg) do
    with {:ok, pid} <- lookup({:handler, guild_id}), do: GenServer.cast(pid, msg)
  end
  def cast(:voice_session, guild_id, msg) do
    with {:ok, pid} <- lookup({:voice_session, guild_id}), do: GenServer.cast(pid, msg)
  end

  def call(:handler, guild_id, msg) do
    with {:ok, pid} <- lookup({:handler, guild_id}), do: GenServer.call(pid, msg)
  end
  def call(:voice_session, guild_id, msg) do
    with {:ok, pid} <- lookup({:voice_session, guild_id}), do: GenServer.call(pid, msg)
  end

  @spec create_handler(Nostrum.Snowflake.t()) :: {:error, any()} | {:ok, pid()}
  def create_handler(guild_id) do
    case Supervisor.start_child(__MODULE__, spec_of(:handler, guild_id)) do
      {:ok, pid} ->
        Logger.debug("Started bot handler #{inspect pid} for guild #{guild_id}")
        {:ok, pid}
      error -> error
    end
  end

  @spec create_handler!(Nostrum.Snowflake.t()) :: no_return() | pid()
  def create_handler!(guild_id), do: get_handler(guild_id) |> Utils.bangify()

  @spec get_handler(Nostrum.Snowflake.t()) :: {:error, any()} | {:ok, pid()}
  def get_handler(guild_id) do
    case lookup({:handler, guild_id}) do
      nil -> create_handler(guild_id)
      other -> other
    end
  end

  @spec get_handler!(Nostrum.Snowflake.t()) :: no_return() | pid()
  def get_handler!(guild_id), do: get_handler(guild_id) |> Utils.bangify()

  @spec create_voice_session(Potcu.Bot.Voice.Structs.SessionInfo.t()) :: {:error, any()} | {:ok, pid()}
  def create_voice_session(session) do
    case lookup({:voice_session, session.guild_id}) do
      nil -> Supervisor.start_child(__MODULE__, spec_of(:voice_session, session))
      {:ok, pid} ->
        #Logger.info("SOHARIM #{inspect pid}")
        #send(pid, {:disconnect})
        #Supervisor.terminate_child(__MODULE__, pid)
        Registry.unregister(@registry_name, {:voice_session, session.guild_id})
        create_voice_session(session)
    end
  end

  @spec create_voice_session!(Potcu.Bot.Voice.Structs.SessionInfo.t()) :: no_return() | pid()
  def create_voice_session!(session), do: create_voice_session(session) |> Utils.bangify()
end
