defmodule Gymrat.Training.Workouts do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Plans.Plan
  alias Gymrat.Workouts.{Workout, WorkoutExercise}

  def list_workouts do
    Repo.all(from w in Workout, where: is_nil(w.deleted_at))
  end

  def get_plan_with_workouts(plan_id) do
    case Repo.get(Plan, plan_id) do
      %Plan{} = plan ->
        active_workouts_query = from w in Workout, where: is_nil(w.deleted_at)
        # Preload workouts, and for each workout, preload its plan
        Repo.preload(plan, workouts: {active_workouts_query, [:plan]})

      nil ->
        {:error, :not_found}
    end
  end

  def get_workout(id) do
    query = from w in Workout, where: w.id == ^id, where: is_nil(w.deleted_at)
    active_exercises_query = from we in WorkoutExercise, where: is_nil(we.deleted_at)

    case Repo.one(query) do
      %Workout{} = workout ->
        {:ok, Repo.preload(workout, workout_exercises: {active_exercises_query, [:workout]})}

      nil ->
        {:error, :not_found}
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
