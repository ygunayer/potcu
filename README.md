<p align="center"><img width="63" height="117" src="explosion-potion.png" /></p>

# potcu
A bot that you can use to bomb voice channels of your choice.

## Prequisites
- Erlang/OTP 22
- Elixir 1.10.2

## Running
To run potcu, you'll need a Discord bot token, and for obvious security reasons this repo does not provide one.

After obtaining a token, create a file named `local.exs` under the `config/` folder, and fill in the Nostrum config. Note that this file is not tracked by Git so you can safely keep your token there.

**config/local.exs**
```elixir
use Mix.Config

config :nostrum,
  token: "...",
  num_shards: 1
```

Once you've placed your token, simply run the Phoenix server with the `MIX_ENV` environment variable set to `local`

```bash
$ MIX_ENV=local mix phx.server
```

## Testing
Simply run

```bash
$ mix test
```

By default, mix attempts to start the actual application before running tests, so if you're just running unit tests you might want to skip this step. To do that, pass the `--no-start` option

```bash
$ mix test --no-start
```

## License
MIT
