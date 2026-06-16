defmodule Gymrat.TrainingFixtures do
  @moduledoc """
  Test helpers for creating training entities (plans, workouts, exercises, sets)
  via direct inserts, used by `Gymrat.Training.*` context tests.
  """

  alias Gymrat.Repo
  alias Gymrat.Plans.Plan
  alias Gymrat.Workouts.{Workout, WorkoutExercise}
  alias Gymrat.Routines.{Routine, RoutineExercise, RoutineSet}
  alias Gymrat.Training.Sets

  import Gymrat.AccountsFixtures, only: [unconfirmed_user_fixture: 0]

  @doc "A persisted user with no email side effects (does not use the magic-link mailer)."
  def training_user_fixture, do: unconfirmed_user_fixture()

  def plan_fixture(creator, attrs \\ %{}) do
    Repo.insert!(%Plan{
      name: Map.get(attrs, :name, "Plan #{System.unique_integer([:positive])}"),
      creator_id: creator.id
    })
  end

  def workout_fixture(plan, attrs \\ %{}) do
    Repo.insert!(%Workout{
      name: Map.get(attrs, :name, "Workout #{System.unique_integer([:positive])}"),
      plan_id: plan.id
    })
  end

  def workout_exercise_fixture(workout, attrs \\ %{}) do
    Repo.insert!(%WorkoutExercise{
      workout_id: workout.id,
      exercise_id: Map.get(attrs, :exercise_id, "0001"),
      body_part: Map.get(attrs, :body_part)
    })
  end

  @doc """
  Creates a set for `user` against `workout_exercise`. Supports `:reps`, `:weight`
  and `:inserted_at` (a `NaiveDateTime`) so tests can place sets inside or outside
  a scoreboard period.
  """
  def set_fixture(user, workout_exercise, attrs \\ %{}) do
    {:ok, set} =
      %{
        reps: 10,
        weight: 50.0,
        user_id: user.id,
        workout_exercise_id: workout_exercise.id
      }
      |> Map.merge(attrs)
      |> Sets.create_set()

    set
  end

  @doc """
  Builds a full chain (plan → workout → workout_exercise) for `user` and returns
  the workout_exercise, the convenient join target for set fixtures.
  """
  def workout_exercise_chain_fixture(user) do
    user
    |> plan_fixture()
    |> workout_fixture()
    |> workout_exercise_fixture()
  end

  def routine_fixture(plan, attrs \\ %{}) do
    Repo.insert!(%Routine{
      name: Map.get(attrs, :name, "Routine #{System.unique_integer([:positive])}"),
      icon: Map.get(attrs, :icon),
      plan_id: plan.id
    })
  end

  def routine_exercise_fixture(routine, attrs \\ %{}) do
    Repo.insert!(%RoutineExercise{
      routine_id: routine.id,
      exercise_id: Map.get(attrs, :exercise_id, "0001"),
      custom_name: Map.get(attrs, :custom_name),
      body_part: Map.get(attrs, :body_part),
      position: Map.get(attrs, :position, 0)
    })
  end

  def routine_set_fixture(routine_exercise, attrs \\ %{}) do
    Repo.insert!(%RoutineSet{
      routine_exercise_id: routine_exercise.id,
      reps_min: Map.get(attrs, :reps_min, 10),
      reps_max: Map.get(attrs, :reps_max),
      rest_seconds: Map.get(attrs, :rest_seconds, 90),
      position: Map.get(attrs, :position, 0)
    })
  end

  @doc """
  Builds a full chain (plan → routine → routine_exercise) for `user` and returns
  the routine_exercise.
  """
  def routine_exercise_chain_fixture(user) do
    user
    |> plan_fixture()
    |> routine_fixture()
    |> routine_exercise_fixture()
  end
end
