defmodule Gymrat.Training.RoutineSetLogsTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Training.RoutineSetLogs

  import Gymrat.TrainingFixtures

  defp set_for(user) do
    user
    |> routine_exercise_chain_fixture()
    |> routine_set_fixture()
  end

  describe "log_set/1" do
    test "records actual performance for the user" do
      user = training_user_fixture()
      set = set_for(user)

      {:ok, log} =
        RoutineSetLogs.log_set(%{
          "reps" => 9,
          "weight" => 60.0,
          "routine_set_id" => set.id,
          "user_id" => user.id
        })

      assert log.reps == 9
      assert log.weight == 60.0
      assert log.user_id == user.id
    end

    test "requires reps and weight" do
      user = training_user_fixture()
      set = set_for(user)

      assert {:error, changeset} =
               RoutineSetLogs.log_set(%{"routine_set_id" => set.id, "user_id" => user.id})

      assert "can't be blank" in errors_on(changeset).reps
      assert "can't be blank" in errors_on(changeset).weight
    end
  end

  describe "todays_logs_by_set/2" do
    test "keys today's logs by routine_set_id for the user" do
      user = training_user_fixture()
      set = set_for(user)

      {:ok, log} =
        RoutineSetLogs.log_set(%{
          "reps" => 10,
          "weight" => 40.0,
          "routine_set_id" => set.id,
          "user_id" => user.id
        })

      result = RoutineSetLogs.todays_logs_by_set([set.id], user.id)
      assert result[set.id].id == log.id
    end

    test "excludes soft-deleted logs" do
      user = training_user_fixture()
      set = set_for(user)

      {:ok, log} =
        RoutineSetLogs.log_set(%{
          "reps" => 10,
          "weight" => 40.0,
          "routine_set_id" => set.id,
          "user_id" => user.id
        })

      RoutineSetLogs.soft_delete_log(log)
      assert RoutineSetLogs.todays_logs_by_set([set.id], user.id) == %{}
    end
  end
end
