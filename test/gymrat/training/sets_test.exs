defmodule Gymrat.Training.SetsTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Repo
  alias Gymrat.Training.Sets

  import Gymrat.TrainingFixtures

  defp days_ago(days) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(-days * 24 * 60 * 60, :second)
    |> NaiveDateTime.truncate(:second)
  end

  describe "get_training_volume_for_plan/2" do
    test "ranks users by volume logged on that plan's workouts only" do
      u1 = training_user_fixture()
      u2 = training_user_fixture()
      plan = plan_fixture(u1)
      we = plan |> workout_fixture() |> workout_exercise_fixture()

      set_fixture(u1, we, %{reps: 10, weight: 100.0})
      set_fixture(u2, we, %{reps: 10, weight: 50.0})

      # u1's work on a different plan must not count toward this plan's board.
      set_fixture(u1, workout_exercise_chain_fixture(u1), %{reps: 10, weight: 999.0})

      result = Sets.get_training_volume_for_plan(plan.id, :all_time)

      assert Enum.map(result, &{&1.user.id, &1.volume}) == [{u1.id, 1000.0}, {u2.id, 500.0}]
    end
  end

  describe "get_personal_records/3" do
    test "returns nil when the exercise has no sets" do
      user = training_user_fixture()
      assert Sets.get_personal_records("0001", nil, user.id) == nil
    end

    test "computes best weight, best single-set volume, and Epley 1RM" do
      user = training_user_fixture()
      we = workout_exercise_chain_fixture(user)

      # weight × (1 + reps/30): 100×(1+5/30)=116.67 ; 80×(1+10/30)=106.67
      set_fixture(user, we, %{reps: 5, weight: 100.0})
      set_fixture(user, we, %{reps: 10, weight: 80.0})

      records = Sets.get_personal_records(we.exercise_id, nil, user.id)

      assert records.max_weight == 100.0
      # single-set volume: 100×5=500 vs 80×10=800
      assert records.best_volume == 800.0
      assert_in_delta records.best_est_1rm, 116.67, 0.01
    end

    test "is scoped to the user" do
      user = training_user_fixture()
      other = training_user_fixture()
      we = workout_exercise_chain_fixture(user)
      set_fixture(user, we, %{reps: 5, weight: 100.0})

      assert Sets.get_personal_records(we.exercise_id, nil, other.id) == nil
    end
  end

  describe "get_training_volume/1" do
    test "returns [] when there are no sets" do
      assert Sets.get_training_volume(:weekly) == []
      assert Sets.get_training_volume(:monthly) == []
      assert Sets.get_training_volume(:all_time) == []
    end

    test "aggregates volume as sum(reps * weight) per user" do
      user = training_user_fixture()
      we = workout_exercise_chain_fixture(user)

      set_fixture(user, we, %{reps: 10, weight: 50.0})
      set_fixture(user, we, %{reps: 5, weight: 20.0})

      assert [%{user: %{id: id}, volume: volume}] = Sets.get_training_volume(:weekly)
      assert id == user.id
      # 10*50 + 5*20 = 600
      assert volume == 600.0
    end

    test "orders users by volume descending and limits the result shape" do
      heavy = training_user_fixture()
      light = training_user_fixture()
      heavy_we = workout_exercise_chain_fixture(heavy)
      light_we = workout_exercise_chain_fixture(light)

      set_fixture(light, light_we, %{reps: 1, weight: 10.0})
      set_fixture(heavy, heavy_we, %{reps: 10, weight: 100.0})

      assert [first, second] = Sets.get_training_volume(:weekly)
      assert first.user.id == heavy.id
      assert first.volume == 1000.0
      assert second.user.id == light.id
      assert second.volume == 10.0
    end

    test ":weekly only counts sets from the current week" do
      user = training_user_fixture()
      we = workout_exercise_chain_fixture(user)

      set_fixture(user, we, %{reps: 10, weight: 10.0, inserted_at: days_ago(0)})
      set_fixture(user, we, %{reps: 10, weight: 10.0, inserted_at: days_ago(60)})

      assert [%{volume: 100.0}] = Sets.get_training_volume(:weekly)
    end

    test ":monthly excludes sets older than the current month" do
      user = training_user_fixture()
      we = workout_exercise_chain_fixture(user)

      set_fixture(user, we, %{reps: 10, weight: 10.0, inserted_at: days_ago(0)})
      # 60 days always lands in an earlier month than today
      set_fixture(user, we, %{reps: 10, weight: 10.0, inserted_at: days_ago(60)})

      assert [%{volume: 100.0}] = Sets.get_training_volume(:monthly)
    end

    test ":all_time counts sets regardless of date" do
      user = training_user_fixture()
      we = workout_exercise_chain_fixture(user)

      set_fixture(user, we, %{reps: 10, weight: 10.0, inserted_at: days_ago(0)})
      set_fixture(user, we, %{reps: 10, weight: 10.0, inserted_at: days_ago(60)})

      assert [%{volume: 200.0}] = Sets.get_training_volume(:all_time)
    end

    test "excludes soft-deleted sets" do
      user = training_user_fixture()
      we = workout_exercise_chain_fixture(user)

      set_fixture(user, we, %{reps: 10, weight: 10.0})
      deleted = set_fixture(user, we, %{reps: 99, weight: 99.0})
      {:ok, _} = Sets.soft_delete_set(deleted)

      assert [%{volume: 100.0}] = Sets.get_training_volume(:all_time)
    end

    test "excludes sets whose workout_exercise is soft-deleted" do
      user = training_user_fixture()
      we = workout_exercise_chain_fixture(user)
      set_fixture(user, we, %{reps: 10, weight: 10.0})

      we
      |> Ecto.Changeset.change(deleted_at: NaiveDateTime.local_now())
      |> Repo.update!()

      assert Sets.get_training_volume(:all_time) == []
    end

    test "excludes sets belonging to soft-deleted users" do
      user = training_user_fixture()
      we = workout_exercise_chain_fixture(user)
      set_fixture(user, we, %{reps: 10, weight: 10.0})

      user
      |> Ecto.Changeset.change(deleted_at: NaiveDateTime.local_now())
      |> Repo.update!()

      assert Sets.get_training_volume(:all_time) == []
    end
  end

  # Builds plan → routine → routine_exercise → routine_set under `plan`.
  defp routine_set_for(plan) do
    plan
    |> routine_fixture()
    |> routine_exercise_fixture()
    |> routine_set_fixture()
  end

  describe "routine volume integration" do
    test "get_training_volume/1 sums workout and routine logs per user" do
      user = training_user_fixture()
      plan = plan_fixture(user)

      we = plan |> workout_fixture() |> workout_exercise_fixture()
      set_fixture(user, we, %{reps: 10, weight: 100.0})

      rs = routine_set_for(plan)
      routine_set_log_fixture(user, rs, %{reps: 10, weight: 50.0})

      assert [%{user: %{id: id}, volume: 1500.0}] = Sets.get_training_volume(:all_time)
      assert id == user.id
    end

    test "get_training_volume_for_plan/2 counts routine logs for that plan only" do
      u1 = training_user_fixture()
      u2 = training_user_fixture()
      plan = plan_fixture(u1)

      rs = routine_set_for(plan)
      routine_set_log_fixture(u1, rs, %{reps: 10, weight: 100.0})
      routine_set_log_fixture(u2, rs, %{reps: 10, weight: 50.0})

      # u1's routine work on another plan must not leak into this board.
      other_rs = routine_set_for(plan_fixture(u1))
      routine_set_log_fixture(u1, other_rs, %{reps: 10, weight: 999.0})

      result = Sets.get_training_volume_for_plan(plan.id, :all_time)
      assert Enum.map(result, &{&1.user.id, &1.volume}) == [{u1.id, 1000.0}, {u2.id, 500.0}]
    end

    test "get_training_volume/1 respects the period for routine logs" do
      user = training_user_fixture()
      rs = routine_set_for(plan_fixture(user))

      routine_set_log_fixture(user, rs, %{reps: 10, weight: 10.0, inserted_at: days_ago(40)})

      assert Sets.get_training_volume(:weekly) == []
      assert [%{volume: 100.0}] = Sets.get_training_volume(:all_time)
    end

    test "get_training_volume/1 excludes soft-deleted routine logs" do
      user = training_user_fixture()
      rs = routine_set_for(plan_fixture(user))
      log = routine_set_log_fixture(user, rs, %{reps: 10, weight: 10.0})

      log
      |> Ecto.Changeset.change(deleted_at: NaiveDateTime.local_now())
      |> Repo.update!()

      assert Sets.get_training_volume(:all_time) == []
    end

    test "get_training_volume/1 excludes time-based (no-reps) routine logs" do
      user = training_user_fixture()

      timed_set =
        plan_fixture(user)
        |> routine_fixture()
        |> routine_exercise_fixture()
        |> routine_set_fixture(%{reps_min: nil, duration_seconds: 30})

      routine_set_log_fixture(user, timed_set, %{reps: nil, duration_seconds: 30, weight: 0.0})

      assert Sets.get_training_volume(:all_time) == []
    end
  end

  describe "list_scored_exercises/1" do
    test "returns distinct exercises that have logged sets across both sources" do
      user = training_user_fixture()
      plan = plan_fixture(user)

      we = plan |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})
      set_fixture(user, we, %{reps: 10, weight: 50.0})

      provider_rs =
        plan
        |> routine_fixture()
        |> routine_exercise_fixture(%{exercise_id: "0002"})
        |> routine_set_fixture()

      routine_set_log_fixture(user, provider_rs, %{reps: 10, weight: 50.0})

      custom_rs =
        plan
        |> routine_fixture()
        |> routine_exercise_fixture(%{exercise_id: nil, custom_name: "Plank"})
        |> routine_set_fixture()

      routine_set_log_fixture(user, custom_rs, %{reps: 10, weight: 0.0})

      result = Sets.list_scored_exercises()

      assert %{exercise_id: "0001", custom_name: nil} in result
      assert %{exercise_id: "0002", custom_name: nil} in result
      assert %{exercise_id: nil, custom_name: "Plank"} in result
    end

    test "dedupes the same exercise logged in both a workout and a routine" do
      user = training_user_fixture()
      plan = plan_fixture(user)

      we = plan |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})
      set_fixture(user, we, %{reps: 10, weight: 50.0})

      rs =
        plan
        |> routine_fixture()
        |> routine_exercise_fixture(%{exercise_id: "0001"})
        |> routine_set_fixture()

      routine_set_log_fixture(user, rs, %{reps: 10, weight: 50.0})

      assert Sets.list_scored_exercises() == [%{exercise_id: "0001", custom_name: nil}]
    end

    test "excludes exercises that have no logged sets" do
      user = training_user_fixture()
      # A workout_exercise with no sets must not appear.
      plan_fixture(user) |> workout_fixture() |> workout_exercise_fixture()

      assert Sets.list_scored_exercises() == []
    end

    test "scopes to a plan when given" do
      user = training_user_fixture()
      plan_a = plan_fixture(user)
      plan_b = plan_fixture(user)

      we_a = plan_a |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})
      set_fixture(user, we_a, %{reps: 10, weight: 50.0})

      we_b = plan_b |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0002"})
      set_fixture(user, we_b, %{reps: 10, weight: 50.0})

      assert Sets.list_scored_exercises(plan_a.id) == [%{exercise_id: "0001", custom_name: nil}]
    end
  end

  describe "get_exercise_max_weight/4" do
    test "ranks users by their heaviest single set for the exercise" do
      u1 = training_user_fixture()
      u2 = training_user_fixture()
      plan = plan_fixture(u1)
      we = plan |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})

      set_fixture(u1, we, %{reps: 5, weight: 120.0})
      set_fixture(u1, we, %{reps: 10, weight: 90.0})
      set_fixture(u2, we, %{reps: 8, weight: 100.0})

      result = Sets.get_exercise_max_weight("0001", nil, :all_time)

      assert Enum.map(result, &{&1.user.id, &1.score}) == [{u1.id, 120.0}, {u2.id, 100.0}]
    end

    test "merges workout and routine sources taking the heavier per user" do
      user = training_user_fixture()
      plan = plan_fixture(user)

      we = plan |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})
      set_fixture(user, we, %{reps: 5, weight: 80.0})

      rs =
        plan
        |> routine_fixture()
        |> routine_exercise_fixture(%{exercise_id: "0001"})
        |> routine_set_fixture()

      routine_set_log_fixture(user, rs, %{reps: 5, weight: 120.0})

      assert [%{user: %{id: id}, score: 120.0}] =
               Sets.get_exercise_max_weight("0001", nil, :all_time)

      assert id == user.id
    end

    test "only counts the requested exercise" do
      user = training_user_fixture()
      plan = plan_fixture(user)

      target = plan |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})
      other = plan |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0002"})

      set_fixture(user, target, %{reps: 5, weight: 60.0})
      set_fixture(user, other, %{reps: 5, weight: 999.0})

      assert [%{score: 60.0}] = Sets.get_exercise_max_weight("0001", nil, :all_time)
    end

    test "matches custom exercises by custom_name" do
      user = training_user_fixture()

      rs =
        plan_fixture(user)
        |> routine_fixture()
        |> routine_exercise_fixture(%{exercise_id: nil, custom_name: "Sandbag Carry"})
        |> routine_set_fixture()

      routine_set_log_fixture(user, rs, %{reps: 1, weight: 70.0})

      assert [%{score: 70.0}] = Sets.get_exercise_max_weight(nil, "Sandbag Carry", :all_time)
    end

    test "respects the period" do
      user = training_user_fixture()
      plan = plan_fixture(user)
      we = plan |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})

      set_fixture(user, we, %{reps: 5, weight: 60.0, inserted_at: days_ago(0)})
      set_fixture(user, we, %{reps: 5, weight: 200.0, inserted_at: days_ago(60)})

      assert [%{score: 60.0}] = Sets.get_exercise_max_weight("0001", nil, :weekly)
      assert [%{score: 200.0}] = Sets.get_exercise_max_weight("0001", nil, :all_time)
    end

    test "scopes to a plan when given" do
      user = training_user_fixture()
      plan_a = plan_fixture(user)
      plan_b = plan_fixture(user)

      we_a = plan_a |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})
      set_fixture(user, we_a, %{reps: 5, weight: 60.0})

      we_b = plan_b |> workout_fixture() |> workout_exercise_fixture(%{exercise_id: "0001"})
      set_fixture(user, we_b, %{reps: 5, weight: 999.0})

      assert [%{score: 60.0}] = Sets.get_exercise_max_weight("0001", nil, :all_time, plan_a.id)
    end
  end
end
