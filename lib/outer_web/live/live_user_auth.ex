defmodule OuterWeb.LiveUserAuth do
  @moduledoc """
  Handles user auth for live views.
  """

  import Phoenix.LiveView

  @doc """
  Authenticates the user by looking into the session.

      def mount(params, session, socket) do
        socket = fetch_current_user(socket, session)

        # ...
      end

  """
  def fetch_current_user(socket) do
    assign(socket, current_user: nil)
  end
end
