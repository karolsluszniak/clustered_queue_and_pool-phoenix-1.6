defmodule OuterWeb.PageController do
  use OuterWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
