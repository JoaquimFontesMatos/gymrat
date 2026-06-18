defmodule Gymrat.Training.Routines do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Plans.{Plan, UserPlans}
  alias Gymrat.Routines.{Routine, RoutineExercise, RoutineSet, RoutineWeekday}

  @doc """
  Loads a plan together with its active routines, each routine preloading its
  exercises (ordered by `position`) and every exercise's planned sets (ordered
  by `position`). Soft-deleted rows are filtered out at each level.
  """
  def get_plan_with_routines(plan_id) do
    query = from p in Plan, where: p.id == ^plan_id, where: is_nil(p.deleted_at)

    case Repo.one(query) do
      %Plan{} = plan ->
        {:ok, Repo.preload(plan, routines: routines_preload_query())}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Lists a plan's active routines (oldest first), each with its active exercises
  preloaded so callers can show a count.
  """
  def list_plan_routines(plan_id) do
    active_exercises = from re in RoutineExercise, where: is_nil(re.deleted_at)

    Repo.all(
      from r in Routine,
        where: r.plan_id == ^plan_id and is_nil(r.deleted_at),
        order_by: r.inserted_at
    )
    |> Repo.preload(routine_exercises: active_exercises)
  end

  @doc """
  Lists the routines scheduled on `weekday` (ISO day number) across the plans
  the user belongs to, each with its active exercises preloaded. Mirrors
  `Workouts.list_my_workouts_by_weekday/2`.
  """
  def list_my_routines_by_weekday(weekday, user_id) do
    active_exercises = from re in RoutineExercise, where: is_nil(re.deleted_at)

    Repo.all(
      from r in Routine,
        join: p in Plan,
        on: r.plan_id == p.id,
        join: up in UserPlans,
        on: up.plan_id == p.id,
        join: rw in RoutineWeekday,
        on: rw.routine_id == r.id,
        where: rw.weekday == ^weekday,
        where: is_nil(r.deleted_at),
        where: is_nil(p.deleted_at),
        where: is_nil(up.deleted_at),
        where: up.user_id == ^user_id,
        preload: [plan: p]
    )
    |> Repo.preload(routine_exercises: active_exercises)
  end

  def get_routine_weekdays(routine_id) do
    Repo.all(from rw in RoutineWeekday, where: rw.routine_id == ^routine_id)
  end

  @doc """
  Loads a single routine with its ordered exercises and their ordered planned
  sets, all filtered on `deleted_at`.
  """
  def get_routine(id) do
    query = from r in Routine, where: r.id == ^id, where: is_nil(r.deleted_at)

    case Repo.one(query) do
      %Routine{} = routine ->
        {:ok, Repo.preload(routine, routine_exercises: ordered_exercises_query())}

      nil ->
        {:error, :not_found}
    end
  end

  def is_routine_from_user(id, user_id) do
    query =
      from r in Routine,
        join: p in Plan,
        on: p.id == r.plan_id,
        where: r.id == ^id,
        where: p.creator_id == ^user_id,
        where: is_nil(r.deleted_at),
        select: r

    case Repo.one(query) do
      %Routine{} -> true
      nil -> false
    end
  end

  def create_routine(attrs \\ %{}) do
    %Routine{}
    |> Routine.changeset(attrs)
    |> Repo.insert()
  end

  def create_routine_with_weekdays(routine_params, weekdays) do
    case create_routine(routine_params) do
      {:ok, routine} ->
        replace_weekdays(routine.id, weekdays)
        {:ok, routine}

      error ->
        error
    end
  end

  def update_routine(%Routine{} = routine, attrs) do
    routine
    |> Routine.changeset(attrs)
    |> Repo.update()
  end

  def update_routine_with_weekdays(%Routine{} = routine, routine_params, new_weekdays) do
    case update_routine(routine, routine_params) do
      {:ok, updated_routine} ->
        replace_weekdays(updated_routine.id, new_weekdays)
        {:ok, updated_routine}

      error ->
        error
    end
  end

  defp replace_weekdays(routine_id, weekdays) do
    Repo.delete_all(from rw in RoutineWeekday, where: rw.routine_id == ^routine_id)

    Enum.each(weekdays, fn weekday_number ->
      %RoutineWeekday{}
      |> RoutineWeekday.changeset(%{routine_id: routine_id, weekday: weekday_number})
      |> Repo.insert!()
    end)
  end

  def soft_delete_routine(%Routine{} = routine) do
    routine
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  def change_routine(%Routine{} = routine, attrs \\ %{}) do
    Routine.changeset(routine, attrs)
  end

  def change_routine_map(attrs) do
    Routine.changeset(%Routine{}, attrs)
  end

  defp routines_preload_query do
    active_routines = from r in Routine, where: is_nil(r.deleted_at), order_by: r.inserted_at
    {active_routines, [routine_exercises: ordered_exercises_query()]}
  end

  defp ordered_exercises_query do
    active_exercises =
      from re in RoutineExercise,
        where: is_nil(re.deleted_at),
        order_by: [asc: re.position, asc: re.id]

    active_sets =
      from rs in RoutineSet,
        where: is_nil(rs.deleted_at),
        order_by: [asc: rs.position, asc: rs.id]

    {active_exercises, [routine_sets: active_sets]}
  end
end
