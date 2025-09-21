defmodule Gymrat.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :color, :string

    has_many :created_plans, Gymrat.Plans.Plan, foreign_key: :creator_id
    has_many :workouts, Gymrat.Workouts.Workout, foreign_key: :creator_id

    many_to_many :plans, Gymrat.Plans.Plan, join_through: "user_plans"

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :color])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
