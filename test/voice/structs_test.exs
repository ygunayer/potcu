defmodule Potcu.Voice.StructsTest do
  use ExUnit.Case, async: true

  alias Potcu.Voice.Structs.{Opcodes, Payload, DiscordVoiceInfo}

  describe "Opcodes" do
    from_cases = [
      {0, {:ok, :identify}},
      {1, {:ok, :select_protocol}},
      {2, {:ok, :ready}},
      {3, {:ok, :heartbeat}},
      {4, {:ok, :session_description}},
      {5, {:ok, :speaking}},
      {6, {:ok, :heartbeat_ack}},
      {7, {:ok, :resume}},
      {8, {:ok, :hello}},
      {9, {:ok, :resumed}},
      {13, {:ok, :client_disconnect}},
      {45, {:error, :unknown, 45}}
    ]

    to_cases = [
      {:identify, {:ok, 0}},
      {:select_protocol, {:ok, 1}},
      {:ready, {:ok, 2}},
      {:heartbeat, {:ok, 3}},
      {:session_description, {:ok, 4}},
      {:speaking, {:ok, 5}},
      {:heartbeat_ack, {:ok, 6}},
      {:resume, {:ok, 7}},
      {:hello, {:ok, 8}},
      {:resumed, {:ok, 9}},
      {:client_disconnect, {:ok, 13}},
      {:foo_bar, {:error, :unknown, :foo_bar}}
    ]

    for {value, expected} <- from_cases do
      @value value
      @expected expected
      test "from(#{inspect value}) should return #{inspect expected}" do
        actual = Opcodes.from_value(@value)
        assert actual == @expected
      end
    end

    for {value, expected} <- to_cases do
      @value value
      @expected expected
      test "from(#{inspect value}) should return #{inspect expected}" do
        actual = Opcodes.to_value(@value)
        assert actual == @expected
      end
    end
  end

  describe "Payload" do
    test "build() should fail if the opcode is unknown" do
      data = %{"foo" => "bar"}
      expected = {:error, :unknown, :foo_bar}
      actual = Payload.build(data, :foo_bar)
      assert actual == expected
    end

    test "build() should succeed if the opcode is valid" do
      data = %{"foo" => "bar"}
      data_string = ~s({"op":0,"d":{"foo":"bar"}})
      expected = {:ok, data_string}
      actual = Payload.build(data, :identify)
      assert actual == expected
    end

    test "parse() should fail if the opcode is unknown" do
      data_string = ~s({"op":45,"d":{"foo":"bar"}})
      expected = {:error, :unknown, 45}
      actual = Payload.parse(data_string)
      assert actual == expected
    end

    test "parse() should succeed if the opcode is valid" do
      data = %{"foo" => "bar"}
      data_string = ~s({"op":0,"d":{"foo":"bar"}})
      expected = {:ok, %{"d" => data, "op" => :identify}}
      actual = Payload.parse(data_string)
      assert actual == expected
    end
  end

  describe "DiscordVoiceInfo" do
    test "from() should fail if the payload is invalid" do
      data = %{"foo" => "bar"}
      expected = {:error, :invalid, data}
      actual = DiscordVoiceInfo.from(data)
      assert actual == expected
    end

    test "from() should succeed if the payload is valid" do
      data = %{"ssrc" => 1, "ip" => "127.0.0.1", "modes" => ["xsalsa20_poly1305", "xsalsa20_poly1305_suffix", "xsalsa20_poly1305_lite"]}
      data_struct = %DiscordVoiceInfo{
        ssrc: 1,
        ip: "127.0.0.1",
        modes: ["xsalsa20_poly1305", "xsalsa20_poly1305_suffix", "xsalsa20_poly1305_lite"]
      }
      expected = {:ok, data_struct}
      actual = DiscordVoiceInfo.from(data)
      assert actual == expected
    end

    test "from() should succeed if the payload is valid and has extra fields" do
      data = %{"ssrc" => 1, "ip" => "127.0.0.1", "modes" => ["xsalsa20_poly1305", "xsalsa20_poly1305_suffix", "xsalsa20_poly1305_lite"], "heartbeat_interval" => 1}
      data_struct = %DiscordVoiceInfo{
        ssrc: 1,
        ip: "127.0.0.1",
        modes: ["xsalsa20_poly1305", "xsalsa20_poly1305_suffix", "xsalsa20_poly1305_lite"]
      }
      expected = {:ok, data_struct}
      actual = DiscordVoiceInfo.from(data)
      assert actual == expected
    end
  end

end
