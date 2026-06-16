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
    |> validate_weekdays()
    |> update_change(:icon, &normalize_icon/1)
  end

  # Only validate the weekday picker when a value was submitted, so the
  # blank initial changeset doesn't surface an error before interaction.
  defp validate_weekdays(changeset) do
    case fetch_change(changeset, :selected_weekdays) do
      {:ok, _} -> validate_length(changeset, :selected_weekdays, min: 1)
      :error -> changeset
    end
  end

  # Treat a blank picker selection ("Auto") as no override.
  defp normalize_icon(""), do: nil
  defp normalize_icon(icon), do: icon
end
