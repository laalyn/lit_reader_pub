defmodule LitReader.Repo do
  use Ecto.Repo,
    otp_app: :lit_reader,
    adapter: Ecto.Adapters.Postgres
end
