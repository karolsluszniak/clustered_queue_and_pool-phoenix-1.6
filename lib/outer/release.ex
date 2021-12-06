defmodule Outer.Release do
  alias Ecto.Migrator
  alias Outer.Repo

  def default do
    migrate()
  end

  def migrate do
    with_repo(&Migrator.run(&1, :up, all: true))
  end

  def rollback(version) do
    with_repo(&Migrator.run(&1, :down, to: version))
  end

  defp with_repo(callback) do
    Application.load(:outer)
    {:ok, _, _} = Migrator.with_repo(Repo, callback)
  end
end
