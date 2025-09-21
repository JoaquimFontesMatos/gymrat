defmodule Gymrat.Repo.Migrations.ChangeSetWorkoutExcercisesIdToWorkoutExerciseId do
  use Ecto.Migration

  def change do
    rename table(:sets), :workout_exercises_id, to: :workout_exercise_id
  end
end
