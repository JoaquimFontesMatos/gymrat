defmodule Gymrat.Training.WorkoutExercises do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.ExerciseFetcher
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

  def get_workout_exercise(workout_exercise) do
    query =
      from we in WorkoutExercise,
        where: we.id == ^workout_exercise,
        where: is_nil(we.deleted_at)

    case Repo.one(query) do
      %WorkoutExercise{} = workout_exercise ->
        {:ok, workout_exercise}

      nil ->
        {:error, :not_found}
    end
  end

  def is_workout_exercise_from_user(workout_exercise_id, user_id) do
    query =
      from we in WorkoutExercise,
        join: w in assoc(we, :workout),
        join: p in assoc(w, :plan),
        where: we.id == ^workout_exercise_id,
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
    workout_id = attrs["workout_id"] || attrs[:workout_id]
    exercise_id = attrs["exercise_id"] || attrs[:exercise_id]

    # The (workout_id, exercise_id) unique index is not filtered on deleted_at,
    # so a soft-deleted row still blocks re-adding. Look up any existing row
    # (custom exercises have a nil exercise_id and never collide) and decide:
    # revive a soft-deleted one, reject an active duplicate, else insert.
    existing =
      if exercise_id do
        Repo.one(
          from we in WorkoutExercise,
            where: we.workout_id == ^workout_id and we.exercise_id == ^exercise_id
        )
      end

    cond do
      is_nil(existing) ->
        %WorkoutExercise{}
        |> WorkoutExercise.changeset(attrs)
        |> Repo.insert()

      is_nil(existing.deleted_at) ->
        {:error, :already_added}

      true ->
        existing
        |> change(deleted_at: nil)
        |> Repo.update()
    end
  end

  @doc """
  Returns a MapSet of `exercise_id`s currently in the workout (active, not
  soft-deleted) — used to flag exercises already added in the search UI.
  """
  def added_exercise_ids(workout_id) do
    Repo.all(
      from we in WorkoutExercise,
        where:
          we.workout_id == ^workout_id and not is_nil(we.exercise_id) and
            is_nil(we.deleted_at),
        select: we.exercise_id
    )
    |> MapSet.new()
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

  @doc """
  Backfills `body_part` on provider exercises that predate the column, so their
  workouts/exercises can derive a muscle icon instead of the dumbbell fallback.

  Each unique `exercise_id` is fetched from the provider once (with `:delay_ms`
  between calls to stay friendly with rate limits) and its first `primaryMuscles`
  value is stored. Custom exercises (no `exercise_id`) and rows that already have
  a `body_part` are left untouched. Returns `%{updated: n, skipped: n}`.
  """
  def backfill_body_parts(opts \\ []) do
    delay_ms = Keyword.get(opts, :delay_ms, 250)

    rows =
      Repo.all(
        from we in WorkoutExercise,
          where: is_nil(we.deleted_at),
          where: is_nil(we.body_part),
          where: not is_nil(we.exercise_id),
          select: {we.id, we.exercise_id}
      )

    muscle_by_exercise =
      rows
      |> Enum.map(&elem(&1, 1))
      |> Enum.uniq()
      |> Map.new(fn exercise_id ->
        muscle = fetch_primary_muscle(exercise_id)
        if delay_ms > 0, do: Process.sleep(delay_ms)
        {exercise_id, muscle}
      end)

    Enum.reduce(rows, %{updated: 0, skipped: 0}, fn {id, exercise_id}, acc ->
      case muscle_by_exercise[exercise_id] do
        nil ->
          %{acc | skipped: acc.skipped + 1}

        muscle ->
          Repo.update_all(
            from(we in WorkoutExercise, where: we.id == ^id),
            set: [body_part: muscle]
          )

          %{acc | updated: acc.updated + 1}
      end
    end)
  end

  defp fetch_primary_muscle(exercise_id) do
    case ExerciseFetcher.fetch_exercise(exercise_id) do
      {:ok, %{"primaryMuscles" => muscles}} -> List.first(List.wrap(muscles))
      _ -> nil
    end
  end
end
