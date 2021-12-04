defmodule OuterWeb.UserSettingsLiveTest do
  use OuterWeb.ConnCase, async: true
  alias Outer.Accounts

  import Outer.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"

      assert {:ok, _view, html} = live(conn)
      assert html =~ "<h1>Settings</h1>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end

    test "updates the user password and resets tokens", %{conn: conn, user: _user} do
      {:ok, view, _} = live(conn, Routes.user_settings_path(conn, :edit))

      assert {:error, {:redirect, %{to: "/users/log_in/complete?token=" <> _}}} =
               view
               |> element("form#update_password")
               |> render_submit(%{
                 "current_password" => valid_user_password(),
                 "user" => %{
                   "password" => "new valid password",
                   "password_confirmation" => "new valid password"
                 }
               })
    end

    test "does not update password on invalid data", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.user_settings_path(conn, :edit))

      html =
        view
        |> element("form#update_password")
        |> render_submit(%{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert html =~ "<h1>Settings</h1>"
      assert html =~ "should be at least 12 character(s)"
      assert html =~ "does not match password"
      assert html =~ "is not valid"
    end

    @tag :capture_log
    test "updates the user email", %{conn: conn, user: _user} do
      {:ok, view, _} = live(conn, Routes.user_settings_path(conn, :edit))

      path = Routes.user_settings_path(conn, :edit)

      assert {:error, {:live_redirect, %{to: ^path}}} =
               view
               |> element("form#update_email")
               |> render_submit(%{
                 "current_password" => valid_user_password(),
                 "user" => %{"email" => unique_user_email()}
               })
    end

    test "does not update email on invalid data", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.user_settings_path(conn, :edit))

      assert html =
               view
               |> element("form#update_email")
               |> render_submit(%{
                 "action" => "update_email",
                 "current_password" => "invalid",
                 "user" => %{"email" => "with spaces"}
               })

      assert html =~ "<h1>Settings</h1>"
      assert html =~ "must have the @ sign and no spaces"
      assert html =~ "is not valid"
    end

    @tag :capture_log
    test "updates the user profile", %{conn: conn, user: user} do
      {:ok, view, _} = live(conn, Routes.user_settings_path(conn, :edit))

      path = Routes.user_settings_path(conn, :edit)

      avatar =
        file_input(view, "#update_profile", :avatar, [
          %{
            last_modified: 1_594_171_879_000,
            name: "avatar.jpg",
            content: File.read!(valid_user_avatar_path()),
            size: File.lstat!(valid_user_avatar_path()).size,
            type: "image/jpeg"
          }
        ])

      assert render_upload(avatar, "avatar.jpg") =~ ~S(<img class="avatar")

      user = Accounts.get_user_by_email(user.email)

      refute user.twitter_handle
      refute user.avatar

      assert {:error, {:redirect, %{to: ^path}}} =
               view
               |> element("form#update_profile")
               |> render_submit(%{
                 "user" => %{"twitter_handle" => "@user"}
               })

      user = Accounts.get_user_by_email(user.email)

      assert user.twitter_handle
      assert user.avatar
    end

    test "does not update profile on invalid Twitter handle", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.user_settings_path(conn, :edit))

      assert html =
               view
               |> element("form#update_profile")
               |> render_submit(%{
                 "user" => %{"twitter_handle" => "invalid"}
               })

      assert html =~ "<h1>Settings</h1>"
      assert html =~ "must be a valid Twitter profile prefixed by @"
    end

    test "does not update profile on invalid avatar", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.user_settings_path(conn, :edit))

      avatar =
        file_input(view, "#update_profile", :avatar, [
          %{
            last_modified: 1_594_171_879_000,
            name: "avatar.jpg",
            content: File.read!(valid_user_avatar_path()),
            size: 10_000_000,
            type: "image/jpeg"
          }
        ])

      assert {:error, [[_, :too_large]]} = render_upload(avatar, "avatar.jpg")
    end
  end
end
