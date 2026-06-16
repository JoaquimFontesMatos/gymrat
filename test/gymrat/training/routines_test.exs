defmodule Gymrat.Training.RoutinesTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Training.Routines

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
end
