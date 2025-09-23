defmodule Gymrat.Training do
  import Ecto.Query, warn: false
  alias Gymrat.Repo

  alias Gymrat.Plans.Plan
  alias Gymrat.Workouts.{Workout, WorkoutExercise, Set}

  # ---------------------------
  # Plans
  # ---------------------------
  def list_plans do
    Repo.all(Plans)
  end

  def list_my_plans(user_id) do
    Repo.all(from p in Plan, where: p.creator_id == ^user_id)
  end

  def get_plan!(id) do
    Repo.get!(Plan, id)
  end

  def create_plan(attrs \\ %{}) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  def change_plan(attrs \\ %{}) do
    %Plan{}
    |> Plan.changeset(attrs)
  end

  # Workouts
  # ---------------------------
  def list_workouts do
    Repo.all(Workout)
  end

  def get_plan_with_workouts(plan_id) do
    case Repo.get(Plan, plan_id) do
      %Plan{} = plan ->
        # Preload workouts, and for each workout, preload its plan
        Repo.preload(plan, workouts: [:plan])

      nil ->
        # Or {:error, :not_found}
        nil
    end
  end

  def get_workout!(id) do
    Repo.get!(Workout, id)
    |> Repo.preload([:workout_exercises, workout_exercises: :sets])
  end

  def create_workout(attrs \\ %{}) do
    %Workout{}
    |> Workout.changeset(attrs)
    |> Repo.insert()
  end

  def change_workout(attrs \\ %{}) do
    %Workout{}
    |> Workout.changeset(attrs)
  end

  # ---------------------------
  # WorkoutExercises
  # ---------------------------
  def list_workout_exercises do
    Repo.all(WorkoutExercise)
  end

  def create_workout_exercise(attrs \\ %{}) do
    %WorkoutExercise{}
    |> WorkoutExercise.changeset(attrs)
    |> Repo.insert()
  end

  # ---------------------------
  # Sets
  # ---------------------------
  def list_sets do
    Repo.all(Set)
  end

  def create_set(attrs \\ %{}) do
    %Set{}
    |> Set.changeset(attrs)
    |> Repo.insert()
  end

  # Preload sets for a workout (through workout_exercises)
  def preload_sets(workout) do
    Repo.preload(workout, workout_exercises: :sets)
  end
end
