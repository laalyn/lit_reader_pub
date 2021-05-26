defmodule LitReaderWeb.ReadController do
  use LitReaderWeb, :controller

  alias LitReader.Accounts
  alias LitReader.Reads

  alias Plug.Conn

  alias LitReaderWeb.FallbackController

  action_fallback LitReaderWeb.FallbackController

  def parse(conn, %{"read_id" => read_id}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      with {:ok, _} <- Reads.parse_source(user_id, read_id) do
        conn
        |> put_status(:ok)
        |> json(%{status: true})
      end
    end
  end

  def get(conn, %{"read_id" => read_id}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      with {:ok, read} <- Reads.get_read(user_id, read_id) do
        conn
        |> put_status(:ok)
        |> json(%{read: read})
      end
    end
  end

  def list(conn, _) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      with {:ok, reads} <- Reads.list_reads(user_id) do
        conn
        |> put_status(:ok)
        |> json(%{reads: reads})
      end
    end
  end

  def create(conn, %{"read" => read, "source_url" => source_url, "configs" => configs}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      try do
        with {:ok, {:ok, read_id}} <- Reads.create_read(user_id, read, source_url, configs) do
          conn
          |> put_status(:ok)
          |> json(%{read_id: read_id})
        end
      rescue err ->
        FallbackController.call(conn, {:error, err})
      end
    end
  end

  def delete(conn, %{"read_id" => read_id}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      with {:ok} <- Reads.delete_read(user_id, read_id) do
        conn
        |> put_status(:ok)
        |> json(%{status: true})
      end
    end
  end
end
