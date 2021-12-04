defmodule OuterWeb.UserSettingsView do
  use OuterWeb, :view

  defp avatar_error_to_string(:too_large), do: "must be an image file below 500KB"
  defp avatar_error_to_string(:not_accepted), do: "must be an image file in JPEG format"
end
