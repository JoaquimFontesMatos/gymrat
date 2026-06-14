defmodule Gymrat.Training.WorkoutExercisesTest do
  use Gymrat.DataCase, async: true

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
end
