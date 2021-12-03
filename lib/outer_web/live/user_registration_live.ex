defmodule OuterWeb.UserRegistrationLive do
  use OuterWeb, :live_controller

  alias Outer.Accounts
  alias Outer.Accounts.User
  alias OuterWeb.LiveUserAuth

  plug {LiveUserAuth, :redirect_if_user_is_authenticated}

  @action_handler true
  def new(socket, _params) do
    changeset = Accounts.change_user_registration(%User{})
    assign(socket, changeset: changeset)
  end

  @event_handler true
  def create(socket, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(socket, :edit, &1)
          )

        socket
        |> put_flash(:info, "User created successfully.")
        |> LiveUserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, changeset: changeset)
    end
  end
end
