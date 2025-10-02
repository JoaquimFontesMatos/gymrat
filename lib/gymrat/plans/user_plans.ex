defmodule Gymrat.Plans.UserPlans do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_plans" do
    field :user_id, :id
    field :plan_id, :id
    field :deleted_at, :naive_datetime
  end

  def changeset(user_plan, attrs) do
    user_plan
    |> cast(attrs, [:user_id, :plan_id, :deleted_at])
    |> validate_required([:user_id, :plan_id])
  end
end
