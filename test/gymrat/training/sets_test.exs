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

      # The User schema omits the deleted_at field even though the column exists,
      # so set it directly to exercise the query's is_nil(u.deleted_at) guard.
      Repo.query!("UPDATE users SET deleted_at = NOW() WHERE id = $1", [user.id])

      assert Sets.get_training_volume(:all_time) == []
    end
  end
end
