defmodule OuterWeb.UserSessionControllerTest do
  use OuterWeb.ConnCase, async: true

  import Outer.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/log_in/complete" do
    test "logs the user in", %{conn: conn, user: user} do
      token = OuterWeb.LoginToken.sign(user.id)
      conn = get(conn, Routes.user_session_path(conn, :create), %{"token" => token})

      assert conn.resp_cookies["_outer_web_user_remember_me"]
      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "emits error message with invalid token", %{conn: conn} do
      token = "invalid"
      conn = get(conn, Routes.user_session_path(conn, :create), %{"token" => token})

      assert redirected_to(conn, 302) == Routes.user_session_path(conn, :new)
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
