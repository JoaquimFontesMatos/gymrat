defmodule Gymrat.Training.RoutineSetLogs do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Routines.RoutineSetLog

  def get_log(id) do
    query = from l in RoutineSetLog, where: l.id == ^id, where: is_nil(l.deleted_at)

    case Repo.one(query) do
      %RoutineSetLog{} = log -> {:ok, log}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Records actual performance for a planned set. `user_id` must be passed
  explicitly by the caller (never cast from user-controlled params).
  """
  def log_set(attrs \\ %{}) do
    %RoutineSetLog{}
    |> RoutineSetLog.changeset(attrs)
    |> Repo.insert()
  end

  def update_log(%RoutineSetLog{} = log, attrs) do
    log
    |> RoutineSetLog.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_log(%RoutineSetLog{} = log) do
    log
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  @doc """
  Loads the logs a user recorded today for the given planned set ids, keyed by
  `routine_set_id` — used to pre-fill the logging form with what's already done.
  """
  def todays_logs_by_set(routine_set_ids, user_id) do
    today = Date.utc_today()
    start_of_day = NaiveDateTime.new!(today, ~T[00:00:00])
    end_of_day = NaiveDateTime.new!(today, ~T[23:59:59])

    Repo.all(
      from l in RoutineSetLog,
        where:
          l.routine_set_id in ^routine_set_ids and
            l.user_id == ^user_id and
            l.inserted_at >= ^start_of_day and l.inserted_at <= ^end_of_day and
            is_nil(l.deleted_at)
    )
    |> Map.new(fn log -> {log.routine_set_id, log} end)
  end

  def change_log(%RoutineSetLog{} = log, attrs \\ %{}) do
    RoutineSetLog.changeset(log, attrs)
  end

  @doc """
  Returns the user's logs for a routine exercise (across its planned sets),
  ordered by day then time, for progress charting. Each row carries the day,
  reps, weight and duration so callers can build per-metric charts.
  """
  def logs_by_day(routine_exercise_id, user_id) do
    Repo.all(
      from l in RoutineSetLog,
        join: rs in assoc(l, :routine_set),
        where: rs.routine_exercise_id == ^routine_exercise_id,
        where: is_nil(rs.deleted_at),
        where: is_nil(l.deleted_at),
        where: l.user_id == ^user_id,
        select: %{
          day: fragment("date(?)", l.inserted_at),
          inserted_at: l.inserted_at,
          reps: l.reps,
          weight: l.weight,
          duration_seconds: l.duration_seconds
        },
        order_by: [asc: fragment("date(?)", l.inserted_at), asc: l.inserted_at]
    )
  end

  @doc """
  Returns the user's per-day totals across a whole routine (volume = Σ reps×weight,
  total reps, and total session duration in seconds — the span from the first to
  the last logged set of the day), for routine-level progress charts.
  """
  def routine_totals_by_day(routine_id, user_id) do
    Repo.all(
      from l in RoutineSetLog,
        join: rs in assoc(l, :routine_set),
        join: re in assoc(rs, :routine_exercise),
        where: re.routine_id == ^routine_id,
        where: is_nil(re.deleted_at),
        where: is_nil(rs.deleted_at),
        where: is_nil(l.deleted_at),
        where: l.user_id == ^user_id,
        group_by: fragment("date(?)", l.inserted_at),
        select: %{
          day: fragment("date(?)", l.inserted_at),
          volume: sum(l.reps * l.weight),
          reps: sum(l.reps),
          duration:
            fragment(
              "ROUND(EXTRACT(EPOCH FROM (MAX(?) - MIN(?))) / 60.0, 1)",
              l.inserted_at,
              l.inserted_at
            )
        },
        order_by: fragment("date(?)", l.inserted_at)
    )
  end
end
