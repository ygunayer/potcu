defmodule Potcu.Utils do
  require Nostrum.Snowflake

  def parse_command(str) when is_binary(str) do
    [first | rest] = String.split(str, ~r/\s+/)
    case first do
      "!potcu" -> interpret_command(rest)
      _ -> :none
    end
  end

  def parse_command(_) do :none end

  def interpret_command(["shoo" | _ ]) do :kick end
  def interpret_command(["sie" | _ ]) do :kick end

  def interpret_command(["gel"]) do :go_to_sender end

  def interpret_command(["bomb" | [url]]) do {:bomb, url} end

  def interpret_command(["bomb" | [channel_id | [url]]]) do
    case Nostrum.Snowflake.cast(channel_id) do
      {:ok, id} -> {:bomb, id, url}
      _ -> :none
    end
  end

  def interpret_command(["help" | _]) do :help end
  def interpret_command([]) do :help end

  def interpret_command(_) do :none end

  def bangify(:ok), do: :ok
  def bangify({:ok}), do: :ok
  def bangify({:ok, result}), do: result
  def bangify({:error, error}), do: raise inspect(error)
end
