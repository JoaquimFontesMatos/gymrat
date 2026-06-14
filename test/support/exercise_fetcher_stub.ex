defmodule Gymrat.ExerciseFetcherStub do
  @moduledoc """
  Deterministic, network-free stand-in for `Gymrat.ExerciseFetcher`, wired in via
  `config :gymrat, :exercise_fetcher` in the test env so `Gymrat.ExerciseCache`
  (and the exercise LiveViews on top of it) never hit RapidAPI in tests.

  Returns fixed data keyed on input, so caching across tests is harmless. The
  special id `"error"` yields an error, exercising failure paths.
  """

  @exercises [
    %{
      "id" => "0001",
      "name" => "Barbell Curl",
      "primaryMuscles" => ["biceps"],
      "secondaryMuscles" => ["forearms"],
      "level" => "beginner",
      "category" => "strength",
      "equipment" => "barbell",
      "force" => "pull",
      "instructions" => ["Curl the bar."]
    },
    %{
      "id" => "0002",
      "name" => "Bench Press",
      "primaryMuscles" => ["chest"],
      "secondaryMuscles" => ["triceps"],
      "level" => "intermediate",
      "category" => "strength",
      "equipment" => "barbell",
      "force" => "push",
      "instructions" => ["Press the bar."]
    }
  ]

  def fetch_exercise("error"), do: {:error, :stub_error}

  def fetch_exercise(id) do
    case Enum.find(@exercises, &(&1["id"] == id)) do
      nil -> {:ok, %{"id" => id, "name" => "Stub #{id}", "primaryMuscles" => ["biceps"]}}
      exercise -> {:ok, exercise}
    end
  end

  def filter_exercises("error"), do: {:error, :stub_error}
  def filter_exercises(_query_string), do: {:ok, @exercises}
end
