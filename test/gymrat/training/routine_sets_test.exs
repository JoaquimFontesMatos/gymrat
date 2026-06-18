defmodule Gymrat.Training.RoutineSetsTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Training.RoutineSets

  import Gymrat.TrainingFixtures

  defp exercise_for(user), do: routine_exercise_chain_fixture(user)

  describe "add_set/1" do
    test "appends with incrementing position" do
      re = exercise_for(training_user_fixture())

      {:ok, s0} = RoutineSets.add_set(%{"routine_exercise_id" => re.id, "reps_min" => 10})
      {:ok, s1} = RoutineSets.add_set(%{"routine_exercise_id" => re.id, "reps_min" => 8})

      assert s0.position == 0
      assert s1.position == 1
    end

    test "rejects reps_max below reps_min" do
      re = exercise_for(training_user_fixture())

      assert {:error, changeset} =
               RoutineSets.add_set(%{
                 "routine_exercise_id" => re.id,
                 "reps_min" => 12,
                 "reps_max" => 8
               })

      assert "must be greater than or equal to the minimum reps" in errors_on(changeset).reps_max
    end

    test "requires reps or a duration" do
      re = exercise_for(training_user_fixture())
      assert {:error, changeset} = RoutineSets.add_set(%{"routine_exercise_id" => re.id})
      assert "set a target reps or a duration" in errors_on(changeset).reps_min
    end

    test "creates a time-based set" do
      re = exercise_for(training_user_fixture())

      {:ok, set} =
        RoutineSets.add_set(%{"routine_exercise_id" => re.id, "duration_seconds" => 30})

      assert set.duration_seconds == 30
      assert is_nil(set.reps_min)
    end

    test "rejects mixing reps and a duration" do
      re = exercise_for(training_user_fixture())

      assert {:error, changeset} =
               RoutineSets.add_set(%{
                 "routine_exercise_id" => re.id,
                 "reps_min" => 10,
                 "duration_seconds" => 30
               })

      assert "use reps or a duration, not both" in errors_on(changeset).duration_seconds
    end
  end

  describe "move_set/2 and soft_delete_set/1" do
    test "swaps adjacent positions" do
      re = exercise_for(training_user_fixture())
      a = routine_set_fixture(re, %{position: 0})
      b = routine_set_fixture(re, %{position: 1})

      assert {:ok, _} = RoutineSets.move_set(a, :down)
      assert Repo.reload(a).position == 1
      assert Repo.reload(b).position == 0
    end

    test "soft delete hides the set from listing" do
      re = exercise_for(training_user_fixture())
      set = routine_set_fixture(re)

      assert {:ok, _} = RoutineSets.soft_delete_set(set)
      assert RoutineSets.list_routine_sets(re.id) == []
    end
  end

  describe "reposition/2" do
    test "assigns positions by the given id order" do
      re = exercise_for(training_user_fixture())
      a = routine_set_fixture(re, %{position: 0})
      b = routine_set_fixture(re, %{position: 1})
      c = routine_set_fixture(re, %{position: 2})

      assert {:ok, _} = RoutineSets.reposition(re.id, [b.id, c.id, a.id])

      assert Repo.reload(b).position == 0
      assert Repo.reload(c).position == 1
      assert Repo.reload(a).position == 2
    end

    test "ignores ids from another exercise" do
      re = exercise_for(training_user_fixture())
      other = exercise_for(training_user_fixture())
      a = routine_set_fixture(re, %{position: 0})
      foreign = routine_set_fixture(other, %{position: 9})

      assert {:ok, _} = RoutineSets.reposition(re.id, [foreign.id, a.id])

      assert Repo.reload(a).position == 1
      assert Repo.reload(foreign).position == 9
    end
  end
end
