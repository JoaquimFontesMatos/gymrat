defmodule Gymrat.Training.PlansTest do
  use Gymrat.DataCase, async: true

  alias Gymrat.Training.Plans

  import Gymrat.TrainingFixtures

  defp create_plan_for(user, name \\ "My Plan") do
    {:ok, plan} = Plans.create_plan(user.id, %{"name" => name, "creator_id" => user.id})
    plan
  end

  describe "create_plan/2" do
    test "creates the plan, links it to the user, and generates a share token" do
      user = training_user_fixture()

      {:ok, plan} = Plans.create_plan(user.id, %{"name" => "Push/Pull", "creator_id" => user.id})

      assert plan.name == "Push/Pull"
      assert is_binary(plan.share_token)
      assert {:ok, _user_plan} = Plans.get_user_plan(user.id, plan.id)
      assert Enum.map(Plans.list_my_plans(user.id), & &1.id) == [plan.id]
    end
  end

  describe "list_my_plans/1" do
    test "returns only the user's own plans" do
      user = training_user_fixture()
      other = training_user_fixture()
      plan = create_plan_for(user)
      _other_plan = create_plan_for(other)

      assert Enum.map(Plans.list_my_plans(user.id), & &1.id) == [plan.id]
      refute plan.id in Enum.map(Plans.list_my_plans(other.id), & &1.id)
    end

    test "excludes soft-deleted plans" do
      user = training_user_fixture()
      plan = create_plan_for(user)
      {:ok, user_plan} = Plans.get_user_plan(user.id, plan.id)

      Plans.soft_delete_plan(plan, user_plan)

      assert Plans.list_my_plans(user.id) == []
    end
  end

  describe "get_plan/1" do
    test "returns the plan when it exists" do
      plan = create_plan_for(training_user_fixture())
      assert {:ok, found} = Plans.get_plan(plan.id)
      assert found.id == plan.id
    end

    test "returns :not_found for a soft-deleted plan" do
      user = training_user_fixture()
      plan = create_plan_for(user)
      {:ok, user_plan} = Plans.get_user_plan(user.id, plan.id)

      Plans.soft_delete_plan(plan, user_plan)

      assert Plans.get_plan(plan.id) == {:error, :not_found}
    end
  end

  describe "import_plan/2" do
    test "imports a plan into another user's plans by share token" do
      owner = training_user_fixture()
      importer = training_user_fixture()
      plan = create_plan_for(owner, "Shared Plan")

      assert {:ok, imported} = Plans.import_plan(plan.share_token, importer.id)
      assert imported.id == plan.id
      assert plan.id in Enum.map(Plans.list_my_plans(importer.id), & &1.id)
    end

    test "returns :not_found for an unknown share token" do
      importer = training_user_fixture()
      assert Plans.import_plan(Ecto.UUID.generate(), importer.id) == {:error, :not_found}
    end

    test "cannot import a soft-deleted plan" do
      owner = training_user_fixture()
      importer = training_user_fixture()
      plan = create_plan_for(owner)
      {:ok, user_plan} = Plans.get_user_plan(owner.id, plan.id)
      Plans.soft_delete_plan(plan, user_plan)

      assert Plans.import_plan(plan.share_token, importer.id) == {:error, :not_found}
    end
  end

  describe "update_plan/2" do
    test "updates the plan name" do
      plan = create_plan_for(training_user_fixture())
      assert {:ok, updated} = Plans.update_plan(plan, %{"name" => "Renamed"})
      assert updated.name == "Renamed"
    end
  end
end
