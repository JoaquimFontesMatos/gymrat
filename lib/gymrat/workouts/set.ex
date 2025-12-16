defmodule Gymrat.Workouts.Set do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sets" do
    field :reps, :integer
    field :weight, :float
    field :deleted_at, :naive_datetime
    belongs_to :user, Gymrat.Accounts.User
    belongs_to :workout_exercise, Gymrat.Workouts.WorkoutExercise

    timestamps()
  end

  def changeset(set, attrs) do
    set
    |> cast(attrs, [:reps, :weight, :workout_exercise_id, :user_id])
    |> validate_required([:reps, :weight, :workout_exercise_id, :user_id])
    |> maybe_put_timestamps(attrs)
  end

  defp maybe_put_timestamps(changeset, attrs) do
    inserted_at =
      attrs
      |> Map.get(:inserted_at, NaiveDateTime.utc_now())
      |> NaiveDateTime.truncate(:second)

    updated_at =
      attrs
      |> Map.get(:updated_at, NaiveDateTime.utc_now())
      |> NaiveDateTime.truncate(:second)

    changeset
    |> put_change(:inserted_at, inserted_at)
    |> put_change(:updated_at, updated_at)
  end
end
