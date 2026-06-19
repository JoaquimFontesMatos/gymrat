defmodule GymratWeb.ScoreboardLive.ExerciseTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  alias Gymrat.Training.Plans

  setup :register_and_log_in_user

  # A custom (non-provider) exercise keeps the label off the ExerciseDB API: its
  # display name is just the custom_name. Returns the planned routine_set.
  defp custom_exercise_set(plan, name) do
    plan
    |> routine_fixture()
    |> routine_exercise_fixture(%{exercise_id: nil, custom_name: name})
    |> routine_set_fixture()
  end

  test "prompts the user to pick an exercise before showing a board", %{conn: conn, user: user} do
    rs = custom_exercise_set(plan_fixture(user), "Plank")
    routine_set_log_fixture(user, rs, %{reps: 1, weight: 40.0})

    {:ok, _lv, html} = live(conn, ~p"/scoreboard/exercise")

    assert html =~ "Pick an exercise"
    assert html =~ "Plank"
  end

  test "ranks users by heaviest set for the selected exercise", %{conn: conn, user: user} do
    rs = custom_exercise_set(plan_fixture(user), "Plank")
    routine_set_log_fixture(user, rs, %{reps: 1, weight: 40.0})
    routine_set_log_fixture(user, rs, %{reps: 1, weight: 90.0})

    {:ok, _lv, html} = live(conn, ~p"/scoreboard/exercise?#{[exercise: "custom:Plank"]}")

    assert html =~ user.name
    assert html =~ "90 kg"
    assert html =~ "Plank — Max Weight"
  end

  test "scopes the board to a selected plan", %{conn: conn, user: user} do
    {:ok, plan} = Plans.create_plan(user.id, %{"name" => "Group Plan", "creator_id" => user.id})
    rs = custom_exercise_set(plan, "Plank")
    routine_set_log_fixture(user, rs, %{reps: 1, weight: 90.0})

    {:ok, lv, _html} =
      live(conn, ~p"/scoreboard/exercise?#{[plan_id: plan.id, exercise: "custom:Plank"]}")

    assert has_element?(lv, "option[value='#{plan.id}'][selected]")
    assert render(lv) =~ "90 kg"
  end

  test "ignores a plan_id the user is not a member of", %{conn: conn} do
    other = training_user_fixture()
    {:ok, plan} = Plans.create_plan(other.id, %{"name" => "Not Mine", "creator_id" => other.id})

    {:ok, lv, _html} = live(conn, ~p"/scoreboard/exercise?#{[plan_id: plan.id]}")

    assert render(lv) =~ "Exercise Scoreboard"
    refute render(lv) =~ "Not Mine"
  end
end
