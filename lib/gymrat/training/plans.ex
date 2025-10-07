defmodule Gymrat.Training.Plans do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo

  alias Gymrat.Plans.{Plan, UserPlans}

  def list_plans do
    Repo.all(from p in Plan, where: is_nil(p.deleted_at))
  end

  def list_my_plans(user_id) do
    Repo.all(
      from p in Plan,
        join: up in UserPlans,
        on: up.plan_id == p.id,
        where: up.user_id == ^user_id and is_nil(p.deleted_at) and is_nil(up.deleted_at),
        select: p
    )
  end

  def get_plan(id) do
    case Repo.one(from p in Plan, where: p.id == ^id, where: is_nil(p.deleted_at)) do
      %Plan{} = plan ->
        {:ok, plan}

      nil ->
        {:error, :not_found}
    end
  end

  def get_user_plan(user_id, plan_id) do
    case Repo.one(
           from up in UserPlans,
             where: up.user_id == ^user_id and up.plan_id == ^plan_id,
             where: is_nil(up.deleted_at)
         ) do
      %UserPlans{} = user_plan ->
        {:ok, user_plan}

      nil ->
        {:error, :not_found}
    end
  end

  def create_user_plan(user_id, plan_id) do
    %UserPlans{}
    |> UserPlans.changeset(%{user_id: user_id, plan_id: plan_id})
    |> Repo.insert()
  end

  def create_plan(user_id, attrs \\ %{}) do
    Repo.transaction(fn ->
      {:ok, plan} =
        %Plan{}
        |> Plan.creation_changeset(attrs)
        |> Repo.insert()

      %UserPlans{}
      |> UserPlans.changeset(%{user_id: user_id, plan_id: plan.id})
      |> Repo.insert()

      plan
    end)
  end

  def import_plan(share_token, user_id) do
    Repo.transaction(fn ->
      # Fetch the plan first
      plan =
        Repo.one(
          from p in Plan,
            where: p.share_token == ^share_token and is_nil(p.deleted_at)
        )

      # Handle case where plan is not found
      if plan == nil do
        Repo.rollback(:not_found)
      end

      # Insert into user_plans
      %UserPlans{}
      |> UserPlans.changeset(%{user_id: user_id, plan_id: plan.id})
      |> Repo.insert!()

      plan
    end)
  end

  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_plan(%Plan{} = plan, %UserPlans{} = user_plan) do
    plan
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()

    soft_delete_user_plan(user_plan)
  end

  def soft_delete_user_plan(%UserPlans{} = user_plan) do
    user_plan
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  def change_plan(%Plan{} = plan, attrs \\ %{}) do
    Plan.creation_changeset(plan, attrs)
  end

  def change_plan_map(attrs) do
    Plan.changeset(%Plan{}, attrs)
  end
end
