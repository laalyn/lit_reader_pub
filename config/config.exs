# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :lit_reader,
  ecto_repos: [LitReader.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :lit_reader, LitReaderWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ePRwPXV4+Vi6ys6FD4Lnj2eYTVhzm7TngmQD3IuCVFDF+Vv2x5fAxYFDQiEkkFx+",
  render_errors: [view: LitReaderWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: LitReader.PubSub,
  live_view: [signing_salt: "ymBDbCNa"]

# Guardian config
config :lit_reader, LitReader.Guardian,
  issuer: "lit_reader",
  secret_key: "RzjnRRvojzc8JVb7br6o0nXUqbMF4ra1WPcwaRhPRdqXxCVu4Wivx0fPmo3wmt3b"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Floki config
config :floki, :html_parser, Floki.HTMLParser.FastHtml

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
