defmodule Potcu.Voice.Structs do
  defmodule Opcodes do
    def opcodes() do
      %{
        :identify => 0,
        :select_protocol => 1,
        :ready => 2,
        :heartbeat => 3,
        :session_description => 4,
        :speaking => 5,
        :heartbeat_ack => 6,
        :resume => 7,
        :hello => 8,
        :resumed => 9,
        :client_disconnect => 13
      }
    end

    def to_value(atom) do
      case opcodes()[atom] do
        nil -> {:error, :unknown, atom}
        value -> {:ok, value}
      end
    end

    def from_value(value) do
      case Enum.find(opcodes(), fn {_, v} -> v == value end) do
        nil -> {:error, :unknown, value}
        {k, _} -> {:ok, k}
      end
    end
  end

  defmodule Payload do
    def identify(user_id, token, guild_id, session_id) do
      %{
        "user_id" => user_id,
        "token" => token,
        "server_id" => guild_id,
        "session_id" => session_id
      }
        |> build(:identify)
    end

    def heartbeat() do
      %{"d" => :os.system_time(:milli_seconds)}
        |> build(:heartbeat)
    end

    def build(data, op) do
      with {:ok, opcode} <- Opcodes.to_value(op),
        {:ok, result} <- %{"op" => opcode, "d" => data}
          |> Poison.encode()
      do
        {:ok, result}
      else
        error -> error
      end
    end

    def parse({:text, text}) do
      with {:ok, parse_result = %{"op" => op_value}} <- Poison.decode(text),
        {:ok, opcode} <- Opcodes.from_value(op_value)
      do
        result = Map.merge(parse_result, %{"op" => opcode})
        {:ok, result}
      else
        error -> error
      end
    end
    def parse(data), do: {:error, :invalid, data}
  end

  defmodule DiscordVoiceInfo do
    defstruct [:ssrc, :ip, :port, :modes]
    @type ssrc :: integer()
    @type ip :: String.t()
    @type modes :: [String.t()]
    @type t :: %__MODULE__{ssrc: ssrc, ip: ip, port: integer(), modes: modes}

    def from(%{"ssrc" => ssrc, "ip" => ip, "modes" => modes}) do
      {:ok, %DiscordVoiceInfo{
        ssrc: ssrc,
        ip: ip,
        modes: modes
      }}
    end

    def from(data), do: {:error, :invalid, data}
  end

  defmodule DiscordHeartbeat do
    defstruct [:timer, :interval]
    @type timer :: timer() | nil
    @type interval :: integer()
    @type t :: %__MODULE__{timer: timer, interval: interval}
  end

  defmodule SessionInfo do
    defstruct [:user_id, :guild_id, :session_id, :endpoint, :token]
    @type user_id :: Nostrum.Snowflake.t()
    @type guild_id :: Nostrum.Snowflake.t()
    @type session_id :: Nostrum.Snowflake.t()
    @type endpoint :: String.t()
    @type token :: String.t()
    @type t :: %__MODULE__{user_id: user_id, guild_id: guild_id, session_id: session_id, endpoint: endpoint, token: token}

    @spec from(any, any, atom | %{endpoint: any, guild_id: any, token: any}) ::
            Potcu.Voice.Structs.SessionInfo.t()
    def from(user_id, session_id, server) do
      %SessionInfo{
        user_id: user_id,
        guild_id: server.guild_id,
        session_id: session_id,
        endpoint: server.endpoint,
        token: server.token
      }
    end
  end

  defmodule WSState do
    defstruct [:conn, :stream]
    @type conn :: pid() | nil
    @type stream :: reference() | nil
    @type t :: %__MODULE__{conn: conn, stream: stream}
  end

  defmodule StateData do
    defstruct [:session, :ws, :udp, :voice, :heartbeat]
    @type session :: SessionInfo.t()
    @type ws :: WSState.t()
    @type udp :: reference() | nil
    @type voice :: DiscordVoiceInfo.t() | nil
    @type heartbeat :: DiscordHeartbeat.t() | nil
    @type t :: %__MODULE__{session: session, ws: ws, udp: udp, voice: voice, heartbeat: heartbeat}
  end
end
