defmodule Gymrat.Training.RoutinesTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Training.{Plans, Routines}

  import Gymrat.TrainingFixtures

  describe "create_routine/1 and get_routine/1" do
    test "creates a routine and loads it with ordered exercises and sets" do
      user = training_user_fixture()
      plan = plan_fixture(user)

      {:ok, routine} =
        Routines.create_routine(%{"name" => "Push A", "plan_id" => plan.id})

      e1 = routine_exercise_fixture(routine, %{exercise_id: "0002", position: 1})
      e0 = routine_exercise_fixture(routine, %{exercise_id: "0001", position: 0})
      routine_set_fixture(e0, %{reps_min: 8, reps_max: 12, position: 0})

      {:ok, loaded} = Routines.get_routine(routine.id)

      assert loaded.name == "Push A"
      assert Enum.map(loaded.routine_exercises, & &1.id) == [e0.id, e1.id]
      assert [%{reps_min: 8, reps_max: 12}] = hd(loaded.routine_exercises).routine_sets
    end

    test "blank name is rejected" do
      plan = plan_fixture(training_user_fixture())
      assert {:error, changeset} = Routines.create_routine(%{"plan_id" => plan.id})
      assert "can't be blank" in errors_on(changeset).name
    end
  end

  describe "soft_delete_routine/1" do
    test "hides the routine from get_routine and list_plan_routines" do
      plan = plan_fixture(training_user_fixture())
      {:ok, routine} = Routines.create_routine(%{"name" => "R", "plan_id" => plan.id})

      assert {:ok, _} = Routines.soft_delete_routine(routine)
      assert Routines.get_routine(routine.id) == {:error, :not_found}
      assert Routines.list_plan_routines(plan.id) == []
    end
  end

  describe "is_routine_from_user/2" do
    test "true only for the plan creator" do
      owner = training_user_fixture()
      other = training_user_fixture()
      plan = plan_fixture(owner)
      {:ok, routine} = Routines.create_routine(%{"name" => "R", "plan_id" => plan.id})

      assert Routines.is_routine_from_user(routine.id, owner.id)
      refute Routines.is_routine_from_user(routine.id, other.id)
    end
  end

  describe "weekday scheduling" do
    # Builds user → plan (linked via user_plans) → routine scheduled on `weekdays`.
    defp scheduled_routine(user, weekdays) do
      plan = plan_fixture(user)
      {:ok, _} = Plans.create_user_plan(user.id, plan.id)

      {:ok, routine} =
        Routines.create_routine_with_weekdays(%{"name" => "R", "plan_id" => plan.id}, weekdays)

      {plan, routine}
    end

    test "create_routine_with_weekdays/2 persists the weekday rows" do
      user = training_user_fixture()
      {_plan, routine} = scheduled_routine(user, [1, 3, 5])

      assert Enum.sort(Enum.map(Routines.get_routine_weekdays(routine.id), & &1.weekday)) ==
               [1, 3, 5]
    end

    test "update_routine_with_weekdays/3 replaces the weekdays" do
      user = training_user_fixture()
      {_plan, routine} = scheduled_routine(user, [1, 3, 5])

      {:ok, _} = Routines.update_routine_with_weekdays(routine, %{"name" => "Renamed"}, [6, 7])

      assert Enum.sort(Enum.map(Routines.get_routine_weekdays(routine.id), & &1.weekday)) ==
               [6, 7]
    end

    test "list_my_routines_by_weekday/2 returns only matching, owned routines" do
      user = training_user_fixture()
      other = training_user_fixture()
      {_plan, routine} = scheduled_routine(user, [1])

      assert Enum.map(Routines.list_my_routines_by_weekday(1, user.id), & &1.id) == [routine.id]
      assert Routines.list_my_routines_by_weekday(2, user.id) == []
      assert Routines.list_my_routines_by_weekday(1, other.id) == []
    end

    test "list_my_routines_by_weekday/2 excludes soft-deleted routines" do
      user = training_user_fixture()
      {_plan, routine} = scheduled_routine(user, [1])

      {:ok, _} = Routines.soft_delete_routine(routine)

      assert Routines.list_my_routines_by_weekday(1, user.id) == []
    end
  end
end
