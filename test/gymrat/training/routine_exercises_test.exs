defmodule Gymrat.Training.RoutineExercisesTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Training.RoutineExercises

  import Gymrat.TrainingFixtures

  defp routine_for(user), do: user |> plan_fixture() |> routine_fixture()

  describe "create_routine_exercise/1" do
    test "appends with an incrementing position" do
      routine = routine_for(training_user_fixture())

      {:ok, a} =
        RoutineExercises.create_routine_exercise(%{
          "routine_id" => routine.id,
          "exercise_id" => "0001"
        })

      {:ok, b} =
        RoutineExercises.create_routine_exercise(%{
          "routine_id" => routine.id,
          "exercise_id" => "0002"
        })

      assert a.position == 0
      assert b.position == 1
    end

    test "rejects re-adding an active provider exercise" do
      routine = routine_for(training_user_fixture())
      attrs = %{"routine_id" => routine.id, "exercise_id" => "0001"}

      assert {:ok, _} = RoutineExercises.create_routine_exercise(attrs)
      assert RoutineExercises.create_routine_exercise(attrs) == {:error, :already_added}
    end

    test "revives a soft-deleted exercise instead of hitting the unique index" do
      routine = routine_for(training_user_fixture())
      attrs = %{"routine_id" => routine.id, "exercise_id" => "0001"}

      {:ok, re} = RoutineExercises.create_routine_exercise(attrs)
      RoutineExercises.soft_delete_routine_exercise(re)

      assert {:ok, revived} = RoutineExercises.create_routine_exercise(attrs)
      assert revived.id == re.id
      assert is_nil(revived.deleted_at)
    end
  end

  describe "move_exercise/2" do
    test "swaps position with the adjacent exercise" do
      routine = routine_for(training_user_fixture())
      a = routine_exercise_fixture(routine, %{exercise_id: "0001", position: 0})
      b = routine_exercise_fixture(routine, %{exercise_id: "0002", position: 1})

      assert {:ok, _} = RoutineExercises.move_exercise(a, :down)

      assert Repo.reload(a).position == 1
      assert Repo.reload(b).position == 0
    end

    test "is a no-op at the boundary" do
      routine = routine_for(training_user_fixture())
      a = routine_exercise_fixture(routine, %{exercise_id: "0001", position: 0})

      assert {:ok, _} = RoutineExercises.move_exercise(a, :up)
      assert Repo.reload(a).position == 0
    end
  end

  describe "is_routine_exercise_from_user/2" do
    test "true only for the plan creator" do
      owner = training_user_fixture()
      other = training_user_fixture()
      re = owner |> plan_fixture() |> routine_fixture() |> routine_exercise_fixture()

      assert RoutineExercises.is_routine_exercise_from_user(re.id, owner.id)
      refute RoutineExercises.is_routine_exercise_from_user(re.id, other.id)
    end
  end
end
