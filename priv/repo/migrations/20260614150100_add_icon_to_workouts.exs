defmodule Gymrat.Repo.Migrations.AddIconToWorkouts do
  use Ecto.Migration

  def change do
    alter table(:workouts) do
      add :icon, :string
    end
  end
end
