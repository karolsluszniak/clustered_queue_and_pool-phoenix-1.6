defmodule OuterWeb.UserSessionLiveTest do
  use OuterWeb.ConnCase, async: true

  import Outer.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Register</a>"
      assert response =~ "Forgot your password?</a>"

      assert {:ok, view, html} = live(conn)
      assert html =~ "<h1>Log in</h1>"

      assert {:error, {:redirect, %{to: "/users/log_in/complete?token=" <> _}}} =
               view
               |> element("form")
               |> render_submit(%{user: %{email: user.email, password: valid_user_password()}})
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end
end
