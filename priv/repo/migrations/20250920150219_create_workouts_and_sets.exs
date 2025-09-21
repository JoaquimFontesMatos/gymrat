defmodule Gymrat.Repo.Migrations.CreateWorkoutsAndSets do
  use Ecto.Migration

  def change do
    create table(:workouts) do
      add :date, :date
      timestamps()
    end

    create table(:sets) do
      add :exercise_id, :string
      add :reps, :integer
      add :weight, :float
      add :workout_id, references(:workouts, on_delete: :delete_all)
      timestamps()
    end

    create index(:sets, [:workout_id])
  end
end
