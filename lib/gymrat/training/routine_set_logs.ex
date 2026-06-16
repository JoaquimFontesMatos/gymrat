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
end
