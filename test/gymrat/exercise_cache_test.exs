defmodule Gymrat.ExerciseCacheTest do
  # async: false — exercises the process-wide ETS cache, cleared per test below.
  use ExUnit.Case, async: false

  alias Gymrat.ExerciseCache

  setup do
    :ets.delete_all_objects(ExerciseCache)
    :ok
  end

  describe "get_exercise/1" do
    test "returns and caches a successful lookup" do
      assert {:ok, exercise} = ExerciseCache.get_exercise("0001")
      assert exercise["name"] == "Barbell Curl"
      assert [{_, ^exercise}] = :ets.lookup(ExerciseCache, {:exercise, "0001"})
    end

    test "reads from the cache rather than the fetcher on a hit" do
      sentinel = %{"id" => "0001", "name" => "Cached"}
      :ets.insert(ExerciseCache, {{:exercise, "0001"}, sentinel})

      assert ExerciseCache.get_exercise("0001") == {:ok, sentinel}
    end

    test "does not cache errors" do
      assert ExerciseCache.get_exercise("error") == {:error, :stub_error}
      assert :ets.lookup(ExerciseCache, {:exercise, "error"}) == []
    end
  end

  describe "get_filtered/1" do
    test "returns and caches a successful lookup" do
      assert {:ok, exercises} = ExerciseCache.get_filtered("muscle=biceps")
      assert length(exercises) == 2
      assert [{_, ^exercises}] = :ets.lookup(ExerciseCache, {:filtered, "muscle=biceps"})
    end

    test "does not cache errors" do
      assert ExerciseCache.get_filtered("error") == {:error, :stub_error}
      assert :ets.lookup(ExerciseCache, {:filtered, "error"}) == []
    end
  end
end
