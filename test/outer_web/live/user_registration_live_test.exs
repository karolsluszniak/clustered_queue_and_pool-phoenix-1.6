defmodule OuterWeb.UserRegistrationLiveTest do
  use OuterWeb.ConnCase, async: true

  import Outer.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</a>"

      assert {:ok, _view, _html} = live(conn)
      assert response =~ "<h1>Register</h1>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end

    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      {:ok, view, _html} = live(conn, Routes.user_registration_path(conn, :new))

      assert {:error, {:redirect, %{to: "/users/log_in/complete?token=" <> _}}} =
               view
               |> element("form")
               |> render_submit(%{user: valid_user_attributes(email: email)})
    end

    test "render errors for invalid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, Routes.user_registration_path(conn, :new))

      html =
        view
        |> element("form")
        |> render_submit(%{user: %{"email" => "with spaces", "password" => "too short"}})

      assert html =~ "<h1>Register</h1>"
      assert html =~ "must have the @ sign and no spaces"
      assert html =~ "should be at least 12 character"
    end
  end
end
