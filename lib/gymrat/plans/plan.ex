defmodule Gymrat.Plans.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plans" do
    field :name, :string

    belongs_to :creator, Gymrat.Accounts.User
    has_many :workouts, Gymrat.Workouts.Workout

    timestamps()
  end

  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:name, :creator_id])
    |> validate_required([:name, :creator_id])
  end
end
