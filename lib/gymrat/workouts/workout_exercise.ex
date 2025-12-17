defmodule Gymrat.Workouts.WorkoutExercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_exercises" do
    field :exercise_id, :string
    field :custom_name, :string
    field :custom_description, :string
    field :custom_image_url, :string
    field :deleted_at, :naive_datetime

    belongs_to :workout, Gymrat.Workouts.Workout
    has_many :sets, Gymrat.Workouts.Set
  end

  def changeset(workout_exercise, attrs) do
    workout_exercise
    |> cast(attrs, [
      :exercise_id,
      :custom_name,
      :custom_description,
      :custom_image_url,
      :workout_id
    ])
    |> validate_required([:workout_id])
    |> validate_exercise_source()
  end

  defp validate_exercise_source(changeset) do
    exercise_id = get_field(changeset, :exercise_id)
    custom_name = get_field(changeset, :custom_name)

    if is_nil(exercise_id) and is_nil(custom_name) do
      add_error(
        changeset,
        :base,
        "Either exercise_id or custom_name must be present"
      )
    else
      changeset
    end
  end
end
