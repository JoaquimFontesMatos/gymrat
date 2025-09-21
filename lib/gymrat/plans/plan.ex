defmodule Gymrat.Plans.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plans" do
    field :name, :string

    belongs_to :creator, Gymrat.Users.User
    many_to_many :users, Gymrat.Users.User, join_through: "user_plans"
    many_to_many :workouts, Gymrat.Workouts.Workout, join_through: "plan_workouts"

    timestamps()
  end

  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:name, :creator_id])
    |> validate_required([:name, :creator_id])
  end
end
