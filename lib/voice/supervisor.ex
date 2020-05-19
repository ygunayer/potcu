defmodule Potcu.Voice.Supervisor do
  use Supervisor
  require Logger

  alias Potcu.Voice.Session
  alias Potcu.Utils

  defmodule ChildLookup do
    use Agent

    def start_link() do
      Agent.start_link(fn -> [] end, name: __MODULE__)
    end

    def add(guild_id, pid) do
      Agent.get_and_update(__MODULE__,
        fn items ->
          new_items = List.keystore(items, guild_id, 0, {guild_id, pid})
          {:ok, new_items}
        end
      )
    end

    def find(guild_id), do: Agent.get(__MODULE__, fn items -> List.keyfind(items, guild_id, 0) end)

    def delete(guild_id), do: Agent.update(__MODULE__, fn items -> List.keydelete(items, guild_id, 0) end)
  end

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      %{id: ChildLookup, start: {ChildLookup, :start_link, []}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def get_session(guild_id) do
    case ChildLookup.find(guild_id) do
      nil -> {:error, :not_found}
      pid -> {:ok, pid}
    end
  end

  def get_session!(guild_id), do: ChildLookup.find(guild_id) |> Utils.bangify()

  def create_session(session) do
    with nil <- ChildLookup.find(session.guild_id),
      {:ok, pid} <-
        Supervisor.start_child(__MODULE__, Session.child_spec(session))
        Process.monit
    do
      ChildLookup.add(session.guild_id, pid)
      {:ok, pid}
    else
      error -> error
    end
  end

  def create_session!(session), do: create_session(session) |> Utils.bangify()

  def stop_session(guild_id) do
    case get_session(guild_id) do
      {:ok, pid} ->
        Supervisor.terminate_child(__MODULE__, pid)
        ChildLookup.delete(guild_id)
        Supervisor.delete_child(__MODULE__, pid)
      error -> error
    end
  end

  def stop_session!(guild_id), do: stop_session(guild_id) |> Utils.bangify()
end
