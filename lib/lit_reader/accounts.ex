defmodule LitReader.Accounts do
  import Ecto.Query, warn: false
  alias LitReader.Repo
  alias LitReader.Guardian

  alias LitReader.Accounts.User
  alias LitReader.Reads

  # authorizes a user (for sockets)
  def auth_user_token!(token) do
    with {:ok, claims} <- token
                          |> Guardian.decode_and_verify do
      {:ok, claims["sub"]}
    else _ ->
      raise "not authorized"
    end
  end

  # authorizes a user
  def auth_user_header(header) do
    with {:ok, claims} <- header
                          |> Enum.at(0)
                          |> String.split(" ", trim: true)
                          |> Enum.at(1)
                          |> Guardian.decode_and_verify do
      {:ok, claims["sub"]}
    else _ ->
      {:error, "not authorized"}
    end
  end

  # authenticates a user
  def auth_user_local(attrs \\ %{}) do
    with {:ok, %User{} = user} <- User
                        |> Repo.get_by(email: attrs["email"])
                        |> Argon2.check_pass(attrs["password"]) do
      Guardian.encode_and_sign(user)
    else _ ->
      {:error, "authentication failed"}
    end
  end

  # creates a user
  def create_user(attrs \\ %{}) do
    Repo.transaction(fn ->
      user = %User{}
             |> User.changeset(attrs)
             |> Repo.insert!

      Reads.create_read(user.id, %{"type" => "play", "name" => "Romeo and Juliet"}, "http://shakespeare.mit.edu/romeo_juliet/full.html", [%{"type" => "act", "match" => [[%{"type" => "html", "value" => "h3" }], [%{"type" => "text", "value" => "ACT"}]] }, %{"type" => "scene", "match" => [[%{"type" => "html", "value" => "h3"}], [%{"type" => "text", "value" => "SCENE"}, %{"type" => "text", "value" => "PROLOGUE"}]]}, %{"type" => "character", "match" => [[%{"type" => "html", "value" => "a"}], [%{"type" => "html", "value" => "b"}]]}, %{"type" => "interaction", "match" => [[%{"type" => "html", "value" => "blockquote"}], [%{"type" => "html", "value" => "a"}]]}, %{"type" => "control", "match" => [[%{"type" => "html", "value" => "blockquote"}], [%{"type" => "html", "value" => "p"}, %{"type" => "html", "value" => "i"}], [%{"type" => "html", "value" => "i"}, %{"type" => "text", "value" => nil}]]}])

      {:ok}
    end)
  end
end