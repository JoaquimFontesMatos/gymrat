defmodule Gymrat.Training.Plans do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo

  alias Gymrat.Plans.Plan

  def list_plans do
    Repo.all(from p in Plan, where: is_nil(p.deleted_at))
  end

  def list_my_plans(user_id) do
    Repo.all(from p in Plan, where: p.creator_id == ^user_id and is_nil(p.deleted_at))
  end

  def get_plan(id) do
    case Repo.one(from p in Plan, where: p.id == ^id, where: is_nil(p.deleted_at)) do
      %Plan{} = plan ->
        {:ok, plan}

      nil ->
        {:error, :not_found}
    end
  end

  def create_plan(attrs \\ %{}) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_plan(%Plan{} = plan) do
    plan
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  def change_plan(%Plan{} = plan, attrs \\ %{}) do
    Plan.changeset(plan, attrs)
  end

  def change_plan_map(attrs) do
    Plan.changeset(%Plan{}, attrs)
  end
end
