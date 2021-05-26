defmodule LitReader.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password], message: "invalid input")
    |> validate_required([:email, :password], message: "some fields are missing")
    |> validate_format(:email, ~r/@/, message: "email is not valid")
    |> validate_length(:password, min: 6, message: "password must be at least 6 characters long")
    |> unique_constraint(:email, message: "email already exists")
    |> change(Argon2.add_hash(attrs["password"]))
  end
end