defmodule Gymrat.Workouts.WorkoutWeekday do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_weekdays" do
    field :weekday, :integer

    belongs_to :workout,
               Gymrat.Workouts.Workout

    timestamps()
  end

  def changeset(ww, attrs) do
    ww
    |> cast(attrs, [:weekday, :workout_id])
    |> validate_required([:weekday, :workout_id])
  end
end
