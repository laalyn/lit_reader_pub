defmodule LitReaderWeb.WidgetController do
  use LitReaderWeb, :controller

  alias LitReader.Accounts
  alias LitReader.Widgets

  alias Plug.Conn

  alias LitReaderWeb.FallbackController

  action_fallback LitReaderWeb.FallbackController

  def run(conn, %{"widget_id" => widget_id}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      try do
        with {:ok, {:ok, result}} <- Widgets.run_widget(user_id, widget_id) do
          conn
          |> put_status(:ok)
          |> json(%{result: result})
        end
      rescue err ->
        FallbackController.call(conn, {:error, err})
      end
    end
  end

  # TODO error handling just choose one method it's not that hard
  def get(conn, %{"widget_id" => widget_id}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      with {:ok, widget} <- Widgets.get_widget(user_id, widget_id) do
        conn
        |> put_status(:ok)
        |> json(%{widget: widget})
      end
    end
  end

  def list(conn, %{"read_id" => read_id}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      with {:ok, widgets} <- Widgets.list_widgets(user_id, read_id) do
        conn
        |> put_status(:ok)
        |> json(%{widgets: widgets})
      end
    end
  end

  def create(conn, %{"widget" => widget}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      with {:ok, widget_id} <- Widgets.create_widget(user_id, widget) do
        conn
        |> put_status(:ok)
        |> json(%{widget_id: widget_id})
      end
    end
  end

  def delete(conn, %{"widget_id" => widget_id}) do
    with {:ok, user_id} <- conn
                           |> Conn.get_req_header("authorization")
                           |> Accounts.auth_user_header do
      with {:ok} <- Widgets.delete_widget(user_id, widget_id) do
        conn
        |> put_status(:ok)
        |> json(%{status: true})
      end
    end
  end
end
