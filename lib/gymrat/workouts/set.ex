defmodule Gymrat.Workouts.Set do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sets" do
    field :reps, :integer
    field :weight, :float
    field :deleted_at, :naive_datetime

    belongs_to :workout_exercise, Gymrat.Workouts.WorkoutExercise

    timestamps()
  end

  def changeset(set, attrs) do
    set
    |> cast(attrs, [:reps, :weight, :workout_exercise_id])
    |> validate_required([:reps, :weight, :workout_exercise_id])
  end
end
