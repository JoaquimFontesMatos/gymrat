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

    test "rejects re-adding an exercise already in the workout" do
      workout = training_user_fixture() |> plan_fixture() |> workout_fixture()
      attrs = %{"workout_id" => workout.id, "exercise_id" => "0001"}

      assert {:ok, _} = WorkoutExercises.create_workout_exercise(attrs)
      assert WorkoutExercises.create_workout_exercise(attrs) == {:error, :already_added}
    end

    test "revives a previously soft-deleted exercise instead of failing the unique index" do
      workout = training_user_fixture() |> plan_fixture() |> workout_fixture()
      attrs = %{"workout_id" => workout.id, "exercise_id" => "0001"}

      {:ok, we} = WorkoutExercises.create_workout_exercise(attrs)
      WorkoutExercises.soft_delete_workout_exercise(we)

      assert {:ok, revived} = WorkoutExercises.create_workout_exercise(attrs)
      assert revived.id == we.id
      assert is_nil(revived.deleted_at)
    end

    test "custom exercises (no exercise_id) can be added repeatedly" do
      workout = training_user_fixture() |> plan_fixture() |> workout_fixture()
      attrs = %{"workout_id" => workout.id, "custom_name" => "My Lift"}

      assert {:ok, a} = WorkoutExercises.create_workout_exercise(attrs)
      assert {:ok, b} = WorkoutExercises.create_workout_exercise(attrs)
      assert a.id != b.id
    end
  end

  describe "added_exercise_ids/1" do
    test "returns active provider exercise_ids, excluding custom and soft-deleted" do
      workout = training_user_fixture() |> plan_fixture() |> workout_fixture()

      _active = workout_exercise_fixture(workout, %{exercise_id: "0001"})
      _custom = workout_exercise_fixture(workout, %{exercise_id: nil})
      deleted = workout_exercise_fixture(workout, %{exercise_id: "0002"})
      WorkoutExercises.soft_delete_workout_exercise(deleted)

      assert WorkoutExercises.added_exercise_ids(workout.id) == MapSet.new(["0001"])
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
