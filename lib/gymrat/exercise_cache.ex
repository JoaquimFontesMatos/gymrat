defmodule Gymrat.ExerciseCache do
  @moduledoc """
  In-memory (ETS) cache in front of `Gymrat.ExerciseFetcher`.

  Exercise data from the external ExerciseDB is effectively static, so once a
  lookup succeeds we keep it for the lifetime of the node. This avoids re-hitting
  the API (and its rate limit) on every page view and lets exercise pages keep
  rendering even when the upstream API is temporarily unavailable.

  Only successful `{:ok, _}` responses are cached — errors are never stored, so a
  transient upstream failure is retried on the next request.
  """

  use GenServer

  alias Gymrat.ExerciseFetcher

  @table __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end

  @doc "Fetch a single exercise by id, caching successful lookups."
  def get_exercise(exercise_id) do
    cached({:exercise, exercise_id}, fn -> ExerciseFetcher.fetch_exercise(exercise_id) end)
  end

  @doc "Fetch the filtered exercise list for a query string, caching successful lookups."
  def get_filtered(query_string) do
    cached({:filtered, query_string}, fn -> ExerciseFetcher.filter_exercises(query_string) end)
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
    :ok
  rescue
    ArgumentError -> :ok
  end
end
