defmodule Gymrat.Training.WorkoutExercises do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Plans.Plan
  alias Gymrat.Workouts.{Workout, WorkoutExercise}

  def get_workout_with_exercises(workout_id) do
    query = from w in Workout, where: w.id == ^workout_id, where: is_nil(w.deleted_at)

    case Repo.one(query) do
      %Workout{} = workout ->
        active_workouts_exercises_query = from we in WorkoutExercise, where: is_nil(we.deleted_at)

        # Preload workouts, and for each workout, preload its plan
        {:ok,
         Repo.preload(workout, workout_exercises: {active_workouts_exercises_query, [:workout]})}

      nil ->
        {:error, :not_found}
    end
  end

  def is_workout_exercise_from_user(id, user_id) do
    query =
      from we in WorkoutExercise,
        join: w in Workout,
        on: w.id == we.workout_id,
        join: p in Plan,
        on: p.id == w.plan_id,
        where: w.id == ^id,
        where: p.creator_id == ^user_id,
        where: is_nil(we.deleted_at),
        select: we

    case Repo.one(query) do
      %WorkoutExercise{} = _ ->
        true

      nil ->
        false
    end
  end

  def list_workout_exercises do
    Repo.all(from we in WorkoutExercise, where: is_nil(we.deleted_at))
  end

  def create_workout_exercise(attrs \\ %{}) do
    %WorkoutExercise{}
    |> WorkoutExercise.changeset(attrs)
    |> Repo.insert()
  end

  def update_workout_exercise(%WorkoutExercise{} = workout_exercise, attrs) do
    workout_exercise
    |> WorkoutExercise.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_workout_exercise(%WorkoutExercise{} = workout_exercise) do
    workout_exercise
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  def change_workout_exercise(%WorkoutExercise{} = workout_exercise, attrs \\ %{}) do
    WorkoutExercise.changeset(workout_exercise, attrs)
  end

  def change_workout_exercise_map(attrs) do
    WorkoutExercise.changeset(%WorkoutExercise{}, attrs)
  end
end
