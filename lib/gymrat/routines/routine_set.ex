defmodule Gymrat.Routines.RoutineSet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_sets" do
    field :position, :integer, default: 0
    field :reps_min, :integer
    field :reps_max, :integer
    field :rest_seconds, :integer
    field :deleted_at, :naive_datetime

    belongs_to :routine_exercise, Gymrat.Routines.RoutineExercise
    has_many :routine_set_logs, Gymrat.Routines.RoutineSetLog

    timestamps()
  end

  def changeset(routine_set, attrs) do
    routine_set
    |> cast(attrs, [:position, :reps_min, :reps_max, :rest_seconds, :routine_exercise_id])
    |> validate_required([:reps_min, :routine_exercise_id])
    |> validate_number(:reps_min, greater_than: 0)
    |> validate_number(:reps_max, greater_than: 0)
    |> validate_number(:rest_seconds, greater_than_or_equal_to: 0)
    |> validate_reps_range()
  end

  # reps_max is optional; when present it must not be below reps_min.
  defp validate_reps_range(changeset) do
    reps_min = get_field(changeset, :reps_min)
    reps_max = get_field(changeset, :reps_max)

    if is_integer(reps_min) and is_integer(reps_max) and reps_max < reps_min do
      add_error(changeset, :reps_max, "must be greater than or equal to the minimum reps")
    else
      changeset
    end
  end
end
