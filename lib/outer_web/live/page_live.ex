defmodule OuterWeb.PageLive do
  use OuterWeb, :live_controller

  @action_handler true
  def index(socket, _params) do
    socket
  end
end
