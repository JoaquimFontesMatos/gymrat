defmodule Gymrat.Routines.RoutineSetLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_set_logs" do
    field :reps, :integer
    field :weight, :float
    field :deleted_at, :naive_datetime

    belongs_to :user, Gymrat.Accounts.User
    belongs_to :routine_set, Gymrat.Routines.RoutineSet

    timestamps()
  end

  def changeset(routine_set_log, attrs) do
    routine_set_log
    |> cast(attrs, [:reps, :weight, :routine_set_id, :user_id])
    |> validate_required([:reps, :weight, :routine_set_id, :user_id])
    |> validate_number(:reps, greater_than: 0)
  end
end
