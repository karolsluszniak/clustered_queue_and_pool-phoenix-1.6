defmodule OuterWeb.PageLiveTest do
  use OuterWeb.ConnCase

  describe "GET /" do
    test "renders home page for guests", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Welcome!"

      assert {:ok, _view, html} = live(conn)
      assert html =~ "Welcome!"
    end

    test "renders home page for logged-in users", %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})

      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Welcome, #{user.email}!"

      assert {:ok, _view, html} = live(conn)
      assert html =~ "Welcome, #{user.email}!"
    end
  end
end
