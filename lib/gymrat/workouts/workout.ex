defmodule Gymrat.Workouts.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string
    field :icon, :string
    field :deleted_at, :naive_datetime

    belongs_to :plan, Gymrat.Plans.Plan
    has_many :workout_exercises, Gymrat.Workouts.WorkoutExercise
    field :selected_weekdays, {:array, :integer}, virtual: true

    timestamps()
  end

  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :icon, :plan_id, :selected_weekdays])
    |> validate_required([:name, :plan_id])
    |> update_change(:icon, &normalize_icon/1)
  end

  # Treat a blank picker selection ("Auto") as no override.
  defp normalize_icon(""), do: nil
  defp normalize_icon(icon), do: icon
end
