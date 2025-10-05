defmodule Gymrat.Repo.Migrations.RemoveWeekdayFromWorkout do
  use Ecto.Migration

  def change do
    alter table(:workouts) do
      remove :weekday
    end
  end
end
