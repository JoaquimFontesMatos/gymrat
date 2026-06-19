defmodule Gymrat.Routines.RoutineExercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_exercises" do
    field :exercise_id, :string
    field :custom_name, :string
    field :custom_description, :string
    field :custom_image_url, :string
    field :body_part, :string
    field :position, :integer, default: 0
    field :deleted_at, :naive_datetime

    belongs_to :routine, Gymrat.Routines.Routine
    has_many :routine_sets, Gymrat.Routines.RoutineSet
  end

  def changeset(routine_exercise, attrs) do
    routine_exercise
    |> cast(attrs, [
      :exercise_id,
      :custom_name,
      :custom_description,
      :custom_image_url,
      :body_part,
      :position,
      :routine_id
    ])
    |> validate_required([:routine_id])
    |> validate_exercise_source()
    |> unique_constraint(:exercise_id,
      name: :routine_exercises_routine_id_exercise_id_index,
      message: "is already in this routine"
    )
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
