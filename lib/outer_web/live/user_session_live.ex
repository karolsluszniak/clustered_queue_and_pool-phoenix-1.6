defmodule OuterWeb.UserSessionLive do
  use OuterWeb, :live_controller
  alias Outer.Accounts
  alias OuterWeb.LiveUserAuth

  plug {LiveUserAuth, :redirect_if_user_is_authenticated}

  @action_handler true
  def new(socket, _params) do
    assign(socket, error_message: nil)
  end

  @event_handler true
  def create(socket, %{
        "user" => %{"email" => email, "password" => password}
      }) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      LiveUserAuth.log_in_user(socket, user)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      socket
      |> put_flash(:error, "Invalid email or password")
    end
  end
end
