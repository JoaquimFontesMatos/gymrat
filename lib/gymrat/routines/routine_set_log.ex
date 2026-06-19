defmodule Gymrat.Routines.RoutineSetLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_set_logs" do
    field :reps, :integer
    field :duration_seconds, :integer
    field :weight, :float
    field :deleted_at, :naive_datetime

    belongs_to :user, Gymrat.Accounts.User
    belongs_to :routine_set, Gymrat.Routines.RoutineSet

    timestamps()
  end

  def changeset(routine_set_log, attrs) do
    routine_set_log
    |> cast(attrs, [:reps, :duration_seconds, :weight, :routine_set_id, :user_id])
    |> validate_required([:routine_set_id, :user_id])
    |> validate_number(:reps, greater_than: 0)
    |> validate_number(:duration_seconds, greater_than: 0)
    |> validate_effort()
    |> maybe_require_weight()
  end

  # A log records either reps or a held duration — at least one is required.
  defp validate_effort(changeset) do
    reps = get_field(changeset, :reps)
    duration = get_field(changeset, :duration_seconds)

    if is_nil(reps) and is_nil(duration) do
      add_error(changeset, :reps, "log reps or a duration")
    else
      changeset
    end
  end

  # Weight is required for reps-based logs (it drives training volume) but
  # optional for timed holds, where it's only relevant for weighted variations.
  defp maybe_require_weight(changeset) do
    if is_nil(get_field(changeset, :duration_seconds)) do
      validate_required(changeset, [:weight])
    else
      changeset
    end
  end
end
