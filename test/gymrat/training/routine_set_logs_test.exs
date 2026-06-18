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

    test "records a timed log with no reps and no weight" do
      user = training_user_fixture()
      set = set_for(user)

      {:ok, log} =
        RoutineSetLogs.log_set(%{
          "duration_seconds" => 45,
          "routine_set_id" => set.id,
          "user_id" => user.id
        })

      assert log.duration_seconds == 45
      assert is_nil(log.reps)
      assert is_nil(log.weight)
    end

    test "requires weight and either reps or a duration" do
      user = training_user_fixture()
      set = set_for(user)

      assert {:error, changeset} =
               RoutineSetLogs.log_set(%{"routine_set_id" => set.id, "user_id" => user.id})

      assert "log reps or a duration" in errors_on(changeset).reps
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

  describe "logs_by_day/2" do
    test "returns the user's logs for the exercise with metrics" do
      user = training_user_fixture()
      re = routine_exercise_chain_fixture(user)
      set = routine_set_fixture(re)
      routine_set_log_fixture(user, set, %{reps: 8, weight: 40.0})

      assert [row] = RoutineSetLogs.logs_by_day(re.id, user.id)
      assert row.reps == 8
      assert row.weight == 40.0
    end

    test "excludes other users and other exercises" do
      user = training_user_fixture()
      other = training_user_fixture()
      re = routine_exercise_chain_fixture(user)
      set = routine_set_fixture(re)

      routine_set_log_fixture(other, set, %{reps: 5, weight: 10.0})

      assert RoutineSetLogs.logs_by_day(re.id, user.id) == []
    end
  end
end
