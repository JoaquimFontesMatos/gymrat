defmodule Gymrat.Training.RoutineExercises do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Routines.{RoutineExercise, RoutineSet}

  def get_routine_exercise(id) do
    query =
      from re in RoutineExercise,
        where: re.id == ^id,
        where: is_nil(re.deleted_at)

    case Repo.one(query) do
      %RoutineExercise{} = routine_exercise -> {:ok, routine_exercise}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Loads a routine exercise with its ordered, active planned sets.
  """
  def get_routine_exercise_with_sets(id) do
    query =
      from re in RoutineExercise,
        where: re.id == ^id,
        where: is_nil(re.deleted_at)

    case Repo.one(query) do
      %RoutineExercise{} = routine_exercise ->
        active_sets =
          from rs in RoutineSet,
            where: is_nil(rs.deleted_at),
            order_by: [asc: rs.position, asc: rs.id]

        {:ok, Repo.preload(routine_exercise, [:routine, routine_sets: active_sets])}

      nil ->
        {:error, :not_found}
    end
  end

  def is_routine_exercise_from_user(routine_exercise_id, user_id) do
    query =
      from re in RoutineExercise,
        join: r in assoc(re, :routine),
        join: p in assoc(r, :plan),
        where: re.id == ^routine_exercise_id,
        where: p.creator_id == ^user_id,
        where: is_nil(re.deleted_at),
        select: re

    case Repo.one(query) do
      %RoutineExercise{} -> true
      nil -> false
    end
  end

  @doc """
  Adds an exercise to a routine, appending it at the end (`position` = current
  max + 1). Mirrors `Training.WorkoutExercises.create_workout_exercise/1`: the
  `(routine_id, exercise_id)` unique index isn't filtered on `deleted_at`, so a
  soft-deleted row still blocks re-adding — revive it instead of inserting.
  Custom exercises (nil `exercise_id`) never collide.
  """
  def create_routine_exercise(attrs \\ %{}) do
    routine_id = attrs["routine_id"] || attrs[:routine_id]
    exercise_id = attrs["exercise_id"] || attrs[:exercise_id]

    existing =
      if exercise_id do
        Repo.one(
          from re in RoutineExercise,
            where: re.routine_id == ^routine_id and re.exercise_id == ^exercise_id
        )
      end

    cond do
      is_nil(existing) ->
        attrs = Map.put(stringify(attrs), "position", next_position(routine_id))

        %RoutineExercise{}
        |> RoutineExercise.changeset(attrs)
        |> Repo.insert()

      is_nil(existing.deleted_at) ->
        {:error, :already_added}

      true ->
        existing
        |> change(deleted_at: nil, position: next_position(routine_id))
        |> Repo.update()
    end
  end

  @doc """
  Returns a MapSet of `exercise_id`s currently in the routine (active, not
  soft-deleted) — used to flag exercises already added in the search UI.
  """
  def added_exercise_ids(routine_id) do
    Repo.all(
      from re in RoutineExercise,
        where:
          re.routine_id == ^routine_id and not is_nil(re.exercise_id) and
            is_nil(re.deleted_at),
        select: re.exercise_id
    )
    |> MapSet.new()
  end

  def soft_delete_routine_exercise(%RoutineExercise{} = routine_exercise) do
    routine_exercise
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  @doc """
  Moves a routine exercise one slot toward `:up` or `:down` by swapping its
  `position` with the adjacent active exercise. No-op at the boundary.
  """
  def move_exercise(%RoutineExercise{} = routine_exercise, direction)
      when direction in [:up, :down] do
    neighbor = adjacent_exercise(routine_exercise, direction)

    case neighbor do
      nil ->
        {:ok, routine_exercise}

      %RoutineExercise{} = neighbor ->
        swap_positions(routine_exercise, neighbor)
    end
  end

  def change_routine_exercise(%RoutineExercise{} = routine_exercise, attrs \\ %{}) do
    RoutineExercise.changeset(routine_exercise, attrs)
  end

  def change_routine_exercise_map(attrs) do
    RoutineExercise.changeset(%RoutineExercise{}, attrs)
  end

  defp next_position(routine_id) do
    max =
      Repo.one(
        from re in RoutineExercise,
          where: re.routine_id == ^routine_id and is_nil(re.deleted_at),
          select: max(re.position)
      )

    (max || -1) + 1
  end

  defp adjacent_exercise(%RoutineExercise{} = re, direction) do
    base =
      from x in RoutineExercise,
        where: x.routine_id == ^re.routine_id and is_nil(x.deleted_at)

    query =
      case direction do
        :up ->
          from x in base,
            where: x.position < ^re.position,
            order_by: [desc: x.position],
            limit: 1

        :down ->
          from x in base,
            where: x.position > ^re.position,
            order_by: [asc: x.position],
            limit: 1
      end

    Repo.one(query)
  end

  defp swap_positions(%RoutineExercise{} = a, %RoutineExercise{} = b) do
    Repo.transaction(fn ->
      {:ok, _} = a |> change(position: b.position) |> Repo.update()
      {:ok, updated} = b |> change(position: a.position) |> Repo.update()
      updated
    end)
  end

  defp stringify(attrs) do
    Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
  end
end
