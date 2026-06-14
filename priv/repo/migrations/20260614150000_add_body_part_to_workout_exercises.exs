defmodule Gymrat.Repo.Migrations.AddBodyPartToWorkoutExercises do
  use Ecto.Migration

  def change do
    alter table(:workout_exercises) do
      add :body_part, :string
    end
  end
end
