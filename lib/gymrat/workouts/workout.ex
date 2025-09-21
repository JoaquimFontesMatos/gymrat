defmodule Gymrat.Workouts.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string

    belongs_to :creator, Gymrat.Users.User
    many_to_many :plans, Gymrat.Plans.Plan, join_through: "plan_workouts"
    has_many :workout_exercises, Gymrat.Workouts.WorkoutExercise

    timestamps()
  end

  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :creator_id])
    |> validate_required([:name, :creator_id])
  end
end
