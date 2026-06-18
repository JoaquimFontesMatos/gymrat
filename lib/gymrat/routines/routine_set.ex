defmodule Gymrat.Routines.RoutineSet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_sets" do
    field :position, :integer, default: 0
    field :reps_min, :integer
    field :reps_max, :integer
    field :duration_seconds, :integer
    field :rest_seconds, :integer
    field :deleted_at, :naive_datetime

    belongs_to :routine_exercise, Gymrat.Routines.RoutineExercise
    has_many :routine_set_logs, Gymrat.Routines.RoutineSetLog

    timestamps()
  end

  @doc "True when the planned set is timed (a hold/duration) rather than reps-based."
  def time_based?(%__MODULE__{duration_seconds: d}), do: is_integer(d)

  def changeset(routine_set, attrs) do
    routine_set
    |> cast(attrs, [
      :position,
      :reps_min,
      :reps_max,
      :duration_seconds,
      :rest_seconds,
      :routine_exercise_id
    ])
    |> validate_required([:routine_exercise_id])
    |> validate_number(:rest_seconds, greater_than_or_equal_to: 0)
    |> validate_mode()
  end

  # A set is either reps-based or time-based — exactly one of `reps_min` /
  # `duration_seconds` must be set.
  defp validate_mode(changeset) do
    reps_min = get_field(changeset, :reps_min)
    duration = get_field(changeset, :duration_seconds)

    cond do
      is_nil(reps_min) and is_nil(duration) ->
        add_error(changeset, :reps_min, "set a target reps or a duration")

      not is_nil(reps_min) and not is_nil(duration) ->
        add_error(changeset, :duration_seconds, "use reps or a duration, not both")

      not is_nil(duration) ->
        validate_number(changeset, :duration_seconds, greater_than: 0)

      true ->
        changeset
        |> validate_number(:reps_min, greater_than: 0)
        |> validate_number(:reps_max, greater_than: 0)
        |> validate_reps_range()
    end
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
