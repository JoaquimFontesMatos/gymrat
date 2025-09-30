defmodule Gymrat.Training do
  import Ecto.Query, warn: false
  alias Gymrat.Repo

  alias Gymrat.Plans.Plan
  alias Gymrat.Workouts.{Workout, WorkoutExercise, Set}

  # Workouts
  # ---------------------------

  # ---------------------------
  # WorkoutExercises
  # ---------------------------

  def get_workout_with_exercises(workout_id) do
    case Repo.get(Workout, workout_id) do
      %Workout{} = workout ->
        # Preload workouts, and for each workout, preload its plan
        Repo.preload(workout, workout_exercises: [:workout])

      nil ->
        # Or {:error, :not_found}
        nil
    end
  end

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

  def get_workout_exercise_with_sets(workout_exercise_id) do
    case Repo.get(WorkoutExercise, workout_exercise_id) do
      %WorkoutExercise{} = workout_exercise ->
        # Preload workouts, and for each workout, preload its plan
        Repo.preload(workout_exercise, sets: [:workout_exercise])

      nil ->
        # Or {:error, :not_found}
        nil
    end
  end

  def get_todays_workout_exercise_with_sets(workout_exercise_id) do
    today = Date.utc_today()

    start_of_day = NaiveDateTime.new!(today, ~T[00:00:00])
    end_of_day = NaiveDateTime.new!(today, ~T[23:59:59])

    sets_query =
      from s in Set,
        where: s.inserted_at >= ^start_of_day and s.inserted_at <= ^end_of_day

    case Repo.get(WorkoutExercise, workout_exercise_id) do
      %WorkoutExercise{} = workout_exercise ->
        Repo.preload(workout_exercise, sets: sets_query)

      nil ->
        nil
    end
  end

  def get_set_sum_weight_by_day(workout_exercise_id) do
    from(s in Set,
      join: we in assoc(s, :workout_exercise),
      where: we.id == ^workout_exercise_id,
      group_by: fragment("date(?)", s.inserted_at),
      select: %{
        day: fragment("date(?)", s.inserted_at),
        total_weight: sum(s.weight)
      },
      order_by: fragment("date(?)", s.inserted_at)
    )
    |> Repo.all()
  end

  def get_set_sum_reps_by_day(workout_exercise_id) do
    from(s in Set,
      join: we in assoc(s, :workout_exercise),
      where: we.id == ^workout_exercise_id,
      group_by: fragment("date(?)", s.inserted_at),
      select: %{
        day: fragment("date(?)", s.inserted_at),
        total_reps: sum(s.reps)
      },
      order_by: fragment("date(?)", s.inserted_at)
    )
    |> Repo.all()
  end

  def change_set(attrs \\ %{}) do
    %Set{}
    |> Set.changeset(attrs)
  end
end
