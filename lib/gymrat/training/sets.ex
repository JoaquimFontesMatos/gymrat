defmodule Gymrat.Training.Sets do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Workouts.{WorkoutExercise, Set}

  def list_sets(user_id) do
    Repo.all(from s in Set, where: s.user_id == ^user_id and is_nil(s.deleted_at))
  end

  def get_set(set_id) do
    query = from s in Set, where: s.id == ^set_id, where: is_nil(s.deleted_at)

    case Repo.one(query) do
      %Set{} = set ->
        {:ok, set}

      nil ->
        {:error, :not_found}
    end
  end

  def get_workout_exercise_with_sets(workout_exercise_id, user_id) do
    query =
      from we in WorkoutExercise,
        where: we.id == ^workout_exercise_id,
        where: is_nil(we.deleted_at)

    case Repo.one(query) do
      %WorkoutExercise{} = workout_exercise ->
        active_sets_query = from s in Set, where: is_nil(s.deleted_at) and s.user_id == ^user_id

        {:ok, Repo.preload(workout_exercise, sets: {active_sets_query, [:workout_exercise]})}

      nil ->
        {:error, :not_found}
    end
  end

  def get_todays_workout_exercise_with_sets(workout_exercise_id, user_id) do
    query =
      from we in WorkoutExercise,
        where: we.id == ^workout_exercise_id,
        where: is_nil(we.deleted_at)

    today = Date.utc_today()

    start_of_day = NaiveDateTime.new!(today, ~T[00:00:00])
    end_of_day = NaiveDateTime.new!(today, ~T[23:59:59])

    sets_query =
      from s in Set,
        where:
          s.inserted_at >= ^start_of_day and s.inserted_at <= ^end_of_day and is_nil(s.deleted_at) and
            s.user_id == ^user_id

    case Repo.one(query) do
      %WorkoutExercise{} = workout_exercise ->
        Repo.preload(workout_exercise, sets: sets_query)

      nil ->
        {:error, :not_found}
    end
  end

  def get_set_sum_weight_by_day(workout_exercise_id, user_id) do
    from(s in Set,
      join: we in assoc(s, :workout_exercise),
      where: we.id == ^workout_exercise_id,
      where: is_nil(we.deleted_at),
      where: is_nil(s.deleted_at),
      where: s.user_id == ^user_id,
      group_by: fragment("date(?)", s.inserted_at),
      select: %{
        day: fragment("date(?)", s.inserted_at),
        total_weight: sum(s.weight)
      },
      order_by: fragment("date(?)", s.inserted_at)
    )
    |> Repo.all()
  end

  def get_sets_weight_by_day(workout_exercise_id, user_id) do
    from(s in Set,
      join: we in assoc(s, :workout_exercise),
      where: we.id == ^workout_exercise_id,
      where: is_nil(we.deleted_at),
      where: is_nil(s.deleted_at),
      where: s.user_id == ^user_id,
      select: %{
        day: fragment("date(?)", s.inserted_at),
        inserted_at: s.inserted_at,
        weight: s.weight
      },
      order_by: [asc: fragment("date(?)", s.inserted_at), asc: s.inserted_at]
    )
    |> Repo.all()
  end

  def get_set_sum_reps_by_day(workout_exercise_id, user_id) do
    from(s in Set,
      join: we in assoc(s, :workout_exercise),
      where: we.id == ^workout_exercise_id,
      where: is_nil(we.deleted_at),
      where: is_nil(s.deleted_at),
      where: s.user_id == ^user_id,
      group_by: fragment("date(?)", s.inserted_at),
      select: %{
        day: fragment("date(?)", s.inserted_at),
        total_reps: sum(s.reps)
      },
      order_by: fragment("date(?)", s.inserted_at)
    )
    |> Repo.all()
  end

  def get_sets_reps_by_day(workout_exercise_id, user_id) do
    from(s in Set,
      join: we in assoc(s, :workout_exercise),
      where: we.id == ^workout_exercise_id,
      where: is_nil(we.deleted_at),
      where: is_nil(s.deleted_at),
      where: s.user_id == ^user_id,
      select: %{
        day: fragment("date(?)", s.inserted_at),
        inserted_at: s.inserted_at,
        reps: s.reps
      },
      order_by: [asc: fragment("date(?)", s.inserted_at), asc: s.inserted_at]
    )
    |> Repo.all()
  end

  def get_weekly_training_volume() do
    query =
      from s in Set,
        join: u in assoc(s, :user),
        where: is_nil(s.deleted_at),
        where: s.inserted_at >= fragment("DATE_TRUNC('week', NOW())"),
        group_by: u.id,
        select: %{
          user: %{
            id: u.id,
            name: u.name,
            color: u.color
          },
          current_week_volume: sum(s.reps * s.weight)
        },
        order_by: [desc: sum(s.reps * s.weight)],
        limit: 50

    Repo.all(query)
  end

  def create_set(attrs \\ %{}) do
    %Set{}
    |> Set.changeset(attrs)
    |> Repo.insert()
  end

  def update_set(%Set{} = set, attrs) do
    set
    |> Set.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_set(%Set{} = set) do
    set
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  def change_set(%Set{} = set, attrs \\ %{}) do
    Set.changeset(set, attrs)
  end

  def change_set_map(attrs) do
    Set.changeset(%Set{}, attrs)
  end

  def smart_delete_old_sets(months_to_keep \\ 5) do
    import Ecto.Query

    # Calculate the two cutoff dates
    five_months_ago_date = Date.add(Date.utc_today(), -months_to_keep * 30)
    one_month_ago_date = Date.add(Date.utc_today(), -30)

    five_months_ago = NaiveDateTime.new!(five_months_ago_date, ~T[00:00:00])
    one_month_ago = NaiveDateTime.new!(one_month_ago_date, ~T[00:00:00])

    # Wrap both steps in a transaction
    Repo.transaction(fn ->
      # --- STEP 1: Identify and Exclude Records to Keep (Retention Window: 1-5 months) ---

      # This query finds the ID of the single LATEST set_date for each month,
      # but only for the data in the special retention window.
      records_to_keep_query =
        from s in Set,
          # Only consider data between 1 month and 5 months ago
          where: s.inserted_at < ^one_month_ago and s.inserted_at > ^five_months_ago,
          # Group by the year and month of the inserted_at
          group_by: [fragment("DATE_TRUNC('month', ?)", s.inserted_at)],
          # Select the inserted_at of the record with the maximum set_date in that month
          select: max(s.inserted_at)

      # Get the list of IDs that MUST NOT be deleted
      inserted_at_to_keep = Repo.all(records_to_keep_query)

      # --- STEP 2: Perform the Deletion ---

      # 1. Target all records older than the full deletion cutoff (5 months ago)
      # OR target records older than 1 month ago AND whose inserted_at is NOT in the 'inserted_at_to_keep' list.
      deletion_query =
        from s in Set,
          where:
            s.inserted_at < ^five_months_ago or
              (s.inserted_at < ^one_month_ago and s.inserted_at not in ^inserted_at_to_keep)

      # Execute the deletion
      {count, _} = Repo.delete_all(deletion_query)

      IO.puts(
        "Deleted #{count} set records older than 1 month, while keeping the latest record for months 2-5."
      )

      {:ok, count}
    end)
  end
end
