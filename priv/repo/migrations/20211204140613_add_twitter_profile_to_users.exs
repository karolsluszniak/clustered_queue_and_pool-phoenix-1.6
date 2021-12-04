defmodule Outer.Repo.Migrations.AddTwitterProfileToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :twitter_handle, :string
    end
  end
end
