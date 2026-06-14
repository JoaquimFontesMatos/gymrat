defmodule Mix.Tasks.Gymrat.BackfillBodyParts do
  @shortdoc "Backfills workout_exercises.body_part from the exercise provider"
  @moduledoc """
  One-time backward-compatibility backfill for the workout/exercise icons.

  Exercises added before the `body_part` column have no muscle stored, so their
  workouts and exercises fall back to the dumbbell icon. This task fetches each
  unique provider exercise once and stores its primary muscle.

  It needs the RapidAPI credentials (and DB) in the environment, so run it
  through Infisical in dev:

      infisical run --env=dev -- mix gymrat.backfill_body_parts

  See `Gymrat.Training.WorkoutExercises.backfill_body_parts/1`.
  """
  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    result = Gymrat.Training.WorkoutExercises.backfill_body_parts()
    Mix.shell().info("Body-part backfill done: #{inspect(result)}")
  end
end
