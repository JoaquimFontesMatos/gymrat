defmodule Gymrat.Training.Workouts do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Plans.{Plan, UserPlans}
  alias Gymrat.Workouts.{Workout, WorkoutExercise}

  def list_workouts do
    Repo.all(from w in Workout, where: is_nil(w.deleted_at))
  end

  def list_my_workouts_by_weekday(weekday, user_id) do
    Repo.all(
      from w in Workout,
        join: p in Plan,
        on: w.plan_id == p.id,
        join: up in UserPlans,
        on: up.plan_id == p.id,
        where: w.weekday == ^weekday,
        where: is_nil(w.deleted_at),
        where: is_nil(p.deleted_at),
        where: not is_nil(w.weekday),
        where: up.user_id == ^user_id
    )
  end

  def get_plan_with_workouts(plan_id) do
    query = from p in Plan, where: p.id == ^plan_id, where: is_nil(p.deleted_at)

    case Repo.one(query) do
      %Plan{} = plan ->
        active_workouts_query = from w in Workout, where: is_nil(w.deleted_at)
        {:ok, Repo.preload(plan, workouts: {active_workouts_query, [:plan]})}

      nil ->
        {:error, :not_found}
    end
  end

  def get_workout(id) do
    query = from w in Workout, where: w.id == ^id, where: is_nil(w.deleted_at)

    case Repo.one(query) do
      %Workout{} = workout ->
        active_exercises_query = from we in WorkoutExercise, where: is_nil(we.deleted_at)
        {:ok, Repo.preload(workout, workout_exercises: {active_exercises_query, [:workout]})}

      nil ->
        {:error, :not_found}
    end
  end

  def is_workout_from_user(id, user_id) do
    query =
      from w in Workout,
        join: p in Plan,
        on: p.id == w.plan_id,
        where: w.id == ^id,
        where: p.creator_id == ^user_id,
        where: is_nil(w.deleted_at),
        select: w

    case Repo.one(query) do
      %Workout{} = _ ->
        true

      nil ->
        false
    end
  end

  def create_workout(attrs \\ %{}) do
    %Workout{}
    |> Workout.changeset(attrs)
    |> Repo.insert()
  end

  def update_workout(%Workout{} = workout, attrs) do
    workout
    |> Workout.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_workout(%Workout{} = workout) do
    workout
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  def change_workout(%Workout{} = workout, attrs \\ %{}) do
    Workout.changeset(workout, attrs)
  end

  def change_workout_map(attrs) do
    Workout.changeset(%Workout{}, attrs)
  end
end
