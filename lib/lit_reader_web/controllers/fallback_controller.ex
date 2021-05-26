defmodule LitReaderWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use LitReaderWeb, :controller

  # screw you
  # TODO make this work better
  def call(conn, err) do
    IO.inspect(err)
    # TODO secure this
    # go through error types
    disp = case elem(err, 1) do
      {:error, %Ecto.Changeset{} = chg} ->
        chg.errors
        |> hd
        |> elem(1)
        |> elem(0)
      %Ecto.InvalidChangesetError{} = chg_err ->
        chg_err.changeset.errors
        |> hd
        |> elem(1)
        |> elem(0)
      %HTTPoison.Error{} = http_err ->
        if http_err.reason == :nxdomain do
          "url doesn't exist"
        else
          "fetching url failed"
        end
      %RuntimeError{} = re ->
        re.message
      str ->
        if String.valid?(str) do
          str
        else
          "something went wrong"
        end
    end
    conn
    |> put_status(:bad_request)
    |> json(%{error: disp})
  end

  # Changeset error
  # def call(conn, {:error, %Ecto.Changeset{}}) do
  #   conn
  #   |> put_status(:bad_request)
  #   |> put_view(LitReaderWeb.ErrorView)
  #   |> render(:"400")
  # end

  # This clause is an example of how to handle resources that cannot be found.
  # def call(conn, {:error, :not_found}) do
  #   conn
  #   |> put_status(:not_found)
  #   |> put_view(LitReaderWeb.ErrorView)
  #   |> render(:"404")
  # end
end
