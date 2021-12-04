defmodule OuterWeb.UserSettingsLive do
  use OuterWeb, :live_controller

  alias Outer.Accounts
  alias OuterWeb.LiveUserAuth

  plug {LiveUserAuth, :require_authenticated_user} when action != :confirm_email
  plug :assign_email_and_password_changesets when action

  @action_handler true
  def edit(socket, _params) do
    allow_upload(socket, :avatar, accept: ~w(.jpg .jpeg), max_file_size: 500_000)
  end

  @event_handler true
  def validate_profile(socket, %{"user" => _user_params}) do
    socket
  end

  @event_handler true
  def update_profile(socket, %{"user" => user_params}) do
    user = socket.assigns.current_user

    avatar_path =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, %{client_name: name} ->
        id = 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
        extension = Path.extname(name)
        final_path = Path.join([System.tmp_dir(), id <> extension])
        File.cp!(path, final_path)
        final_path
      end)
      |> List.first()

    user_params =
      if avatar_path, do: Map.put(user_params, "avatar", avatar_path), else: user_params

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _user} ->
        if avatar_path, do: File.rm(avatar_path)

        socket
        |> put_flash(:info, "Profile updated successfully.")
        |> push_redirect(to: Routes.user_settings_path(socket, :edit))

      {:error, changeset} ->
        if avatar_path, do: File.rm(avatar_path)

        assign(socket, profile_changeset: changeset)
    end
  end

  @event_handler true
  def update_email(socket, params) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_settings_url(socket, :confirm_email, &1)
        )

        socket
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> push_redirect(to: Routes.user_settings_path(socket, :edit))

      {:error, changeset} ->
        assign(socket, email_changeset: changeset)
    end
  end

  @event_handler true
  def update_password(socket, params) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        socket
        |> put_flash(:info, "Password updated successfully.")
        |> LiveUserAuth.log_in_user(user)

      {:error, changeset} ->
        assign(socket, password_changeset: changeset)
    end
  end

  defp assign_email_and_password_changesets(socket) do
    user = socket.assigns.current_user

    socket
    |> assign(:profile_changeset, Accounts.change_user_profile(user))
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
