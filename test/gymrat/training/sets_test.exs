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
end
