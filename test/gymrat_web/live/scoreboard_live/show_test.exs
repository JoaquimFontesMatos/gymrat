defmodule GymratWeb.ScoreboardLive.ShowTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  alias Gymrat.Training.Plans

  setup :register_and_log_in_user

  test "renders the global leaderboard with the user's volume", %{conn: conn, user: user} do
    we = workout_exercise_chain_fixture(user)
    set_fixture(user, we, %{reps: 10, weight: 100.0})

    {:ok, _lv, html} = live(conn, ~p"/scoreboard")

    assert html =~ user.name
    assert html =~ "1000 kg"
  end

  test "scopes the leaderboard to a selected plan", %{conn: conn, user: user} do
    {:ok, plan} = Plans.create_plan(user.id, %{"name" => "Group Plan", "creator_id" => user.id})
    we = plan |> workout_fixture() |> workout_exercise_fixture()
    set_fixture(user, we, %{reps: 10, weight: 100.0})

    {:ok, lv, _html} = live(conn, ~p"/scoreboard?#{[plan_id: plan.id]}")

    assert has_element?(lv, "option[value='#{plan.id}'][selected]")
    assert render(lv) =~ "1000 kg"
  end

  test "ignores a plan_id the user is not a member of", %{conn: conn, user: _user} do
    other = training_user_fixture()
    {:ok, plan} = Plans.create_plan(other.id, %{"name" => "Not Mine", "creator_id" => other.id})

    # A non-member plan_id is rejected and the board falls back to global without
    # crashing or leaking the other group's data.
    {:ok, lv, _html} = live(conn, ~p"/scoreboard?#{[plan_id: plan.id]}")

    assert render(lv) =~ "Weekly Scoreboard"
    refute render(lv) =~ "Not Mine"
  end
end
