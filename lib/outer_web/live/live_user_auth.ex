defmodule OuterWeb.LiveUserAuth do
  @moduledoc """
  Handles user auth for live views.
  """

  import Phoenix.LiveView
  import Phoenix.LiveController
  alias Outer.Accounts
  alias OuterWeb.LoginToken
  alias OuterWeb.Router.Helpers, as: Routes

  @doc """
  Logs the user in.

  As a live view cannot modify session, this function safely redirects to HTTP endpoint which can.
  In the end, the `OuterWeb.UserAuth.log_in_user/3` function is invoked.
  """
  def log_in_user(socket, user) do
    token = LoginToken.sign(user.id)
    redirect(socket, to: Routes.user_session_path(socket, :create, token: token))
  end

  @doc """
  Authenticates the user by looking into the session.

      def mount(params, session, socket) do
        socket = fetch_current_user(socket, session)

        # ...
      end

  """
  def fetch_current_user(socket) do
    user_token = get_session(socket, :user_token)
    user = user_token && Accounts.get_user_by_session_token(user_token)

    assign(socket, current_user: user)
  end

  @doc """
  Used for mounts and event handlers that require the user to not be authenticated.

      def handle_event("save", params, socket) do
        socket =
          with %{redirected: nil} <- redirect_if_user_is_authenticated(socket) do
            # ...
          end

        {:noreply, socket}
      end

  """
  def redirect_if_user_is_authenticated(socket) do
    socket = fetch_current_user(socket)

    if socket.assigns.current_user do
      push_redirect(socket, to: "/")
    else
      socket
    end
  end
end
