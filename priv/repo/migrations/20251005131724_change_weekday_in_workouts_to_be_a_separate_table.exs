defmodule Gymrat.Repo.Migrations.ChangeWeekdayInWorkoutsToBeASeparateTable do
  use Ecto.Migration

  def change do
    create table(:workout_weekdays) do
      add :workout_id, references(:workouts, on_delete: :delete_all), null: false
      add :weekday, :integer, null: false

      timestamps()
    end

    create index(:workout_weekdays, [:workout_id])
  end
end
