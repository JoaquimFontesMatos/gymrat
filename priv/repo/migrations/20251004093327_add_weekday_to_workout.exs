defmodule Gymrat.Repo.Migrations.AddWeekdayToWorkout do
  use Ecto.Migration

  def change do
    alter table(:workouts) do
      add :weekday, :string
    end
  end
end
