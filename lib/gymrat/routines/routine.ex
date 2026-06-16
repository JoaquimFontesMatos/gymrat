defmodule Gymrat.Routines.Routine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routines" do
    field :name, :string
    field :icon, :string
    field :deleted_at, :naive_datetime

    belongs_to :plan, Gymrat.Plans.Plan
    has_many :routine_exercises, Gymrat.Routines.RoutineExercise

    timestamps()
  end

  def changeset(routine, attrs) do
    routine
    |> cast(attrs, [:name, :icon, :plan_id])
    |> validate_required([:name, :plan_id])
    |> update_change(:icon, &normalize_icon/1)
  end

  # Treat a blank picker selection ("Auto") as no override.
  defp normalize_icon(""), do: nil
  defp normalize_icon(icon), do: icon
end
