defmodule Gymrat.Workouts.WorkoutExercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_exercises" do
    field :exercise_id, :string
    field :deleted_at, :naive_datetime

    belongs_to :workout, Gymrat.Workouts.Workout
    has_many :sets, Gymrat.Workouts.Set
  end

  def changeset(workout_exercise, attrs) do
    workout_exercise
    |> cast(attrs, [:exercise_id, :workout_id])
    |> validate_required([:exercise_id, :workout_id])
  end
end
