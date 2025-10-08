defmodule Gymrat.Repo.Migrations.AddUserWeight do
  use Ecto.Migration

  def change do
    create table(:user_weights) do
      add :weight, :float
      add :deleted_at, :naive_datetime

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
