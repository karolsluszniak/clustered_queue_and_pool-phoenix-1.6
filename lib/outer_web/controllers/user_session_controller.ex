defmodule OuterWeb.UserSessionController do
  use OuterWeb, :controller

  alias Outer.Accounts
  alias OuterWeb.{LoginToken, UserAuth}

  def create(conn, %{"token" => token}) do
    case LoginToken.verify(token) do
      {:ok, user_id} ->
        user = Accounts.get_user!(user_id)
        UserAuth.log_in_user(conn, user)

      {:error, :expired} ->
        conn
        |> put_flash(:error, "Login token expired.")
        |> redirect(to: Routes.user_session_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
