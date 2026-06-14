defmodule Gymrat.Training.UserWeightsTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Repo
  alias Gymrat.Accounts.UserWeight
  alias Gymrat.Training.UserWeights

  import Gymrat.TrainingFixtures

  defp weight_fixture(user, attrs \\ %{}) do
    {:ok, uw} =
      UserWeights.create_user_weight(Map.merge(%{weight: 80.0, user_id: user.id}, attrs))

    uw
  end

  describe "create_user_weight/1" do
    test "requires weight and user_id" do
      assert {:error, changeset} = UserWeights.create_user_weight(%{})
      assert %{weight: ["can't be blank"], user_id: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "get_user_weight/1" do
    test "returns the weight, or :not_found once soft-deleted" do
      uw = weight_fixture(training_user_fixture())
      assert {:ok, found} = UserWeights.get_user_weight(uw.id)
      assert found.id == uw.id

      UserWeights.soft_delete_user_weight(uw)
      assert UserWeights.get_user_weight(uw.id) == {:error, :not_found}
    end
  end

  describe "get_my_weights/1" do
    test "scopes to the user and excludes soft-deleted entries" do
      user = training_user_fixture()
      other = training_user_fixture()
      keep = weight_fixture(user, %{weight: 81.0})
      gone = weight_fixture(user, %{weight: 82.0})
      _theirs = weight_fixture(other, %{weight: 90.0})

      UserWeights.soft_delete_user_weight(gone)

      assert Enum.map(UserWeights.get_my_weights(user.id), & &1.id) == [keep.id]
    end
  end

  describe "get_weights_by_insertdate/1" do
    test "returns {inserted_at, weight} ordered ascending by date" do
      user = training_user_fixture()

      Repo.insert!(%UserWeight{
        user_id: user.id,
        weight: 70.0,
        inserted_at: ~N[2026-01-01 08:00:00],
        updated_at: ~N[2026-01-01 08:00:00]
      })

      Repo.insert!(%UserWeight{
        user_id: user.id,
        weight: 72.0,
        inserted_at: ~N[2026-02-01 08:00:00],
        updated_at: ~N[2026-02-01 08:00:00]
      })

      assert Enum.map(UserWeights.get_weights_by_insertdate(user.id), & &1.weight) == [70.0, 72.0]
    end
  end

  describe "update_user_weight/2" do
    test "updates the recorded weight" do
      uw = weight_fixture(training_user_fixture())
      assert {:ok, updated} = UserWeights.update_user_weight(uw, %{weight: 79.5})
      assert updated.weight == 79.5
    end
  end
end
