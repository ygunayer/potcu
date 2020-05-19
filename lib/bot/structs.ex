defmodule Potcu.Bot.Structs do
  alias Nostrum.Snowflake
  alias Nostrum.Struct.Guild.Voice

  defmodule VoiceStatus do
    defstruct [:status, :handler, :channel_id, :session_id, :server]
    @type status :: :not_connected | :preparing | :connecting | :connected
    @type channel_id :: Snowflake.t() | nil
    @type session_id :: Snowflake.t() | nil
    @type handler :: pid() | nil
    @type server :: Voice.Server.t() | nil

    @type t :: %__MODULE__{
      handler: handler,
      session_id: session_id(),
      server: server
    }
  end

  defmodule BombStatus do
    defstruct [:status, :target, :timer, :media]
    @type status :: :idle | :counting_down | :bombing
    @type target :: Snowflake.t() | nil
    @type timer :: reference() | nil
    @type media :: {:url, String.t()} | {:path, String.t()} | nil
  end

  defmodule StateData do
    defstruct [:status, :voice, :bomb]
    @type voice :: VoiceStatus
    @type bomb :: BombStatus
  end
end
