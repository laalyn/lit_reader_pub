defmodule LitReaderWeb.UserController do
  use LitReaderWeb, :controller

  alias LitReader.Accounts

  alias Plug.Conn

  alias LitReaderWeb.FallbackController

  action_fallback LitReaderWeb.FallbackController

  def cur(conn, _) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      conn
      |> put_status(:ok)
      |> json(%{user_id: user_id})
    end
  end

  def auth(conn, %{"user" => user_params}) do
    with {:ok, token, _claims} <- Accounts.auth_user_local(user_params) do
      conn
      |> put_status(:ok)
      |> json(%{token: token})
    end
  end

  def create(conn, %{"user" => user_params}) do
    try do
      with {:ok, {:ok}} <- Accounts.create_user(user_params) do
        conn
        |> put_status(:created)
        |> json(%{status: true})
      end
    rescue err ->
      FallbackController.call(conn, {:error, err})
    end
  end
end
