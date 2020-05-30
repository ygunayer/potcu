defmodule UtilsTest do
  use ExUnit.Case, async: true

  describe "Utils.parse_command/1" do
    cases = [
      {[5, <<"x">>, "", "foo", "!potc", "!potcuaaaa"], :none},
      {["!potcu", "!potcu help"], :help},
      {["!potcu sie", "!potcu shoo"], :kick},
      {["!potcu bomb x"], {:bomb, "x"}},
      {["!potcu bomb 89918932789497856 y"], {:bomb, Nostrum.Snowflake.cast!(89918932789497856), "y"}},
      {["!potcu bomb x y"], :none},
      {["!potcu gel"], :go_to_sender}
    ]

    for {values, expected} <- cases do
      for value <- values do
        @value value
        @expected expected
        test "should return #{inspect expected} for #{inspect value}" do
          actual = Potcu.Utils.parse_command(@value)
          assert actual == @expected
        end
      end
    end
  end
end
