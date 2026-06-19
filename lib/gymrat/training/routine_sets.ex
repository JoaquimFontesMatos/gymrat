defmodule Gymrat.Training.RoutineSets do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Routines.RoutineSet

  def get_routine_set(id) do
    query = from rs in RoutineSet, where: rs.id == ^id, where: is_nil(rs.deleted_at)

    case Repo.one(query) do
      %RoutineSet{} = routine_set -> {:ok, routine_set}
      nil -> {:error, :not_found}
    end
  end

  def list_routine_sets(routine_exercise_id) do
    Repo.all(
      from rs in RoutineSet,
        where: rs.routine_exercise_id == ^routine_exercise_id and is_nil(rs.deleted_at),
        order_by: [asc: rs.position, asc: rs.id]
    )
  end

  @doc """
  Adds a planned set to a routine exercise, appended at the end.
  """
  def add_set(attrs \\ %{}) do
    routine_exercise_id = attrs["routine_exercise_id"] || attrs[:routine_exercise_id]
    attrs = Map.put(stringify(attrs), "position", next_position(routine_exercise_id))

    %RoutineSet{}
    |> RoutineSet.changeset(attrs)
    |> Repo.insert()
  end

  def update_set(%RoutineSet{} = routine_set, attrs) do
    routine_set
    |> RoutineSet.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_set(%RoutineSet{} = routine_set) do
    routine_set
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  @doc """
  Moves a planned set one slot toward `:up` or `:down` within its exercise by
  swapping `position` with the adjacent active set. No-op at the boundary.
  """
  def move_set(%RoutineSet{} = routine_set, direction) when direction in [:up, :down] do
    case adjacent_set(routine_set, direction) do
      nil -> {:ok, routine_set}
      %RoutineSet{} = neighbor -> swap_positions(routine_set, neighbor)
    end
  end

  @doc """
  Sets each active set's `position` to its index in `ordered_ids`, scoped to
  `routine_exercise_id`. Backs drag-and-drop reordering.
  """
  def reposition(routine_exercise_id, ordered_ids) do
    Repo.transaction(fn ->
      ordered_ids
      |> Enum.with_index()
      |> Enum.each(fn {id, index} ->
        from(rs in RoutineSet,
          where:
            rs.id == ^id and rs.routine_exercise_id == ^routine_exercise_id and
              is_nil(rs.deleted_at)
        )
        |> Repo.update_all(set: [position: index])
      end)
    end)
  end

  def change_routine_set(%RoutineSet{} = routine_set, attrs \\ %{}) do
    RoutineSet.changeset(routine_set, attrs)
  end

  def change_routine_set_map(attrs) do
    RoutineSet.changeset(%RoutineSet{}, attrs)
  end

  defp next_position(routine_exercise_id) do
    max =
      Repo.one(
        from rs in RoutineSet,
          where: rs.routine_exercise_id == ^routine_exercise_id and is_nil(rs.deleted_at),
          select: max(rs.position)
      )

    (max || -1) + 1
  end

  defp adjacent_set(%RoutineSet{} = rs, direction) do
    base =
      from x in RoutineSet,
        where: x.routine_exercise_id == ^rs.routine_exercise_id and is_nil(x.deleted_at)

    query =
      case direction do
        :up ->
          from x in base, where: x.position < ^rs.position, order_by: [desc: x.position], limit: 1

        :down ->
          from x in base, where: x.position > ^rs.position, order_by: [asc: x.position], limit: 1
      end

    Repo.one(query)
  end

  defp swap_positions(%RoutineSet{} = a, %RoutineSet{} = b) do
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
