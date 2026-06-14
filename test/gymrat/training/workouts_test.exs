defmodule Gymrat.Training.WorkoutsTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Training.{Plans, Workouts}

  import Gymrat.TrainingFixtures

  # Builds user → plan (linked via user_plans) → workout scheduled on `weekdays`.
  defp scheduled_workout(user, weekdays) do
    plan = plan_fixture(user)
    {:ok, _} = Plans.create_user_plan(user.id, plan.id)

    {:ok, workout} =
      Workouts.create_workout_with_weekdays(
        %{"name" => "Leg Day", "plan_id" => plan.id},
        weekdays
      )

    {plan, workout}
  end

  describe "create_workout_with_weekdays/2" do
    test "creates the workout and its weekday rows" do
      workout = plan_fixture(training_user_fixture())

      {:ok, created} =
        Workouts.create_workout_with_weekdays(%{"name" => "A", "plan_id" => workout.id}, [1, 3, 5])

      assert created.name == "A"
      assert Enum.sort(Enum.map(Workouts.get_workout_weekdays(created.id), & &1.weekday)) == [1, 3, 5]
    end
  end

  describe "get_workout/1" do
    test "returns the workout with active exercises preloaded" do
      workout = workout_fixture(plan_fixture(training_user_fixture()))
      assert {:ok, found} = Workouts.get_workout(workout.id)
      assert found.id == workout.id
      assert found.workout_exercises == []
    end

    test "returns :not_found for a soft-deleted workout" do
      workout = workout_fixture(plan_fixture(training_user_fixture()))
      Workouts.soft_delete_workout(workout)
      assert Workouts.get_workout(workout.id) == {:error, :not_found}
    end
  end

  describe "list_my_workouts_by_weekday/2" do
    test "returns the user's workouts scheduled on that weekday" do
      user = training_user_fixture()
      {_plan, workout} = scheduled_workout(user, [1])

      assert Enum.map(Workouts.list_my_workouts_by_weekday(1, user.id), & &1.id) == [workout.id]
      assert Workouts.list_my_workouts_by_weekday(2, user.id) == []
    end

    test "does not return another user's workouts" do
      user = training_user_fixture()
      other = training_user_fixture()
      {_plan, _workout} = scheduled_workout(user, [1])

      assert Workouts.list_my_workouts_by_weekday(1, other.id) == []
    end

    test "excludes soft-deleted workouts" do
      user = training_user_fixture()
      {_plan, workout} = scheduled_workout(user, [1])

      Workouts.soft_delete_workout(workout)

      assert Workouts.list_my_workouts_by_weekday(1, user.id) == []
    end
  end

  describe "is_workout_from_user/2" do
    test "is true for the plan creator and false for others" do
      user = training_user_fixture()
      other = training_user_fixture()
      workout = workout_fixture(plan_fixture(user))

      assert Workouts.is_workout_from_user(workout.id, user.id)
      refute Workouts.is_workout_from_user(workout.id, other.id)
    end
  end

  describe "update_workout_with_weekdays/3" do
    test "replaces the workout's weekdays" do
      user = training_user_fixture()
      {_plan, workout} = scheduled_workout(user, [1, 2])

      {:ok, updated} =
        Workouts.update_workout_with_weekdays(workout, %{"name" => "Renamed"}, [6, 7])

      assert updated.name == "Renamed"
      assert Enum.sort(Enum.map(Workouts.get_workout_weekdays(workout.id), & &1.weekday)) == [6, 7]
    end
  end
end
