defmodule Gymrat.Workouts.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string

    belongs_to :plan, Gymrat.Plans.Plan
    has_many :workout_exercises, Gymrat.Workouts.WorkoutExercise

    timestamps()
  end

  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :plan_id])
    |> validate_required([:name, :plan_id])
  end
end
