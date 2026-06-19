defmodule Gymrat.ExerciseCache do
  @moduledoc """
  Cache in front of `Gymrat.ExerciseFetcher`.

  Exercise data from the external ExerciseDB is effectively static, so once a
  lookup succeeds we keep it for the lifetime of the node. This avoids re-hitting
  the API (and its rate limit) on every page view and lets exercise pages keep
  rendering even when the upstream API is temporarily unavailable.

  Reads are served from an in-memory ETS table. When `:exercise_cache_file` is
  configured, successful lookups are *also* persisted to a DETS file and reloaded
  into ETS on boot. The upstream API is unreliable (frequent 504s), so without
  persistence a server restart would empty the cache and force every page to hit
  the flaky API again — exactly the "breaks on restart" failure this avoids.

  Only successful `{:ok, _}` responses are cached — errors (including 200s with an
  empty/invalid body, see `Gymrat.ExerciseFetcher`) are never stored, so a
  transient upstream failure is retried on the next request rather than poisoning
  the cache.
  """

  use GenServer

  alias Gymrat.ExerciseFetcher

  @table __MODULE__
  @dets :"#{__MODULE__}.Dets"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    open_dets()
    {:ok, %{}}
  end

  @impl true
  def terminate(_reason, _state) do
    if persist_path(), do: :dets.close(@dets)
    :ok
  end

  @doc "Fetch a single exercise by id, caching successful lookups."
  def get_exercise(exercise_id) do
    cached({:exercise, exercise_id}, fn -> fetcher().fetch_exercise(exercise_id) end)
  end

  @doc "Fetch the filtered exercise list for a query string, caching successful lookups."
  def get_filtered(query_string) do
    cached({:filtered, query_string}, fn -> fetcher().filter_exercises(query_string) end)
  end

  # The upstream fetcher is configurable so tests can swap in a stub instead of
  # hitting the external API.
  defp fetcher, do: Application.get_env(:gymrat, :exercise_fetcher, ExerciseFetcher)

  # Path to the on-disk DETS cache, or nil to disable persistence (e.g. in tests).
  defp persist_path, do: Application.get_env(:gymrat, :exercise_cache_file)

  # Opens the DETS file (if configured) and warms ETS from it so a restart serves
  # previously-cached exercises without touching the API. Any failure (missing or
  # corrupt file) degrades to an empty, in-memory-only cache.
  defp open_dets do
    case persist_path() do
      nil ->
        :ok

      path ->
        File.mkdir_p!(Path.dirname(path))
        {:ok, @dets} = :dets.open_file(@dets, file: String.to_charlist(path), type: :set)
        :dets.to_ets(@dets, @table)
        :ok
    end
  rescue
    _ -> :ok
  end

  defp cached(key, fun) do
    case lookup(key) do
      {:ok, value} ->
        {:ok, value}

      :miss ->
        case fun.() do
          {:ok, value} ->
            insert(key, value)
            {:ok, value}

          other ->
            other
        end
    end
  end

  # ETS access is wrapped so a missing table (cache process not started yet or
  # restarting) degrades to an uncached direct fetch instead of crashing.
  defp lookup(key) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :miss
    end
  rescue
    ArgumentError -> :miss
  end

  defp insert(key, value) do
    :ets.insert(@table, {key, value})

    # Flush immediately: writes are rare (once per unique exercise/query per node),
    # and a dev restart via Ctrl-C never runs `terminate`, so we cannot rely on a
    # clean close to persist. Without the sync the last writes are lost on restart.
    if persist_path() do
      :dets.insert(@dets, {key, value})
      :dets.sync(@dets)
    end

    :ok
  rescue
    ArgumentError -> :ok
  end
end
