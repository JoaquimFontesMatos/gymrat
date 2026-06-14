defmodule Gymrat.Training.WorkoutExercisesTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Repo
  alias Gymrat.Training.WorkoutExercises

  import Gymrat.TrainingFixtures

  describe "create_workout_exercise/1" do
    test "persists the provider body_part" do
      workout = training_user_fixture() |> plan_fixture() |> workout_fixture()

      {:ok, we} =
        WorkoutExercises.create_workout_exercise(%{
          "workout_id" => workout.id,
          "exercise_id" => "0001",
          "body_part" => "quadriceps"
        })

      assert we.body_part == "quadriceps"
    end

    test "body_part is optional (custom exercises have none)" do
      workout = training_user_fixture() |> plan_fixture() |> workout_fixture()

      {:ok, we} =
        WorkoutExercises.create_workout_exercise(%{
          "workout_id" => workout.id,
          "custom_name" => "My Lift"
        })

      assert we.body_part == nil
    end
  end

  describe "backfill_body_parts/1" do
    test "leaves custom exercises and already-filled rows untouched (no provider calls)" do
      workout = training_user_fixture() |> plan_fixture() |> workout_fixture()

      custom = workout_exercise_fixture(workout, %{exercise_id: nil})
      filled = workout_exercise_fixture(workout, %{exercise_id: "0001", body_part: "biceps"})

      # Neither row qualifies for backfill, so no provider request is made.
      assert WorkoutExercises.backfill_body_parts(delay_ms: 0) == %{updated: 0, skipped: 0}

      assert Repo.reload(custom).body_part == nil
      assert Repo.reload(filled).body_part == "biceps"
    end
  end
end
