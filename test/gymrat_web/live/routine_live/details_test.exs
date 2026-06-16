defmodule GymratWeb.RoutineLive.DetailsTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  setup :register_and_log_in_user

  defp routine_with_exercises(user) do
    plan = plan_fixture(user)
    routine = routine_fixture(plan)
    a = routine_exercise_fixture(routine, %{exercise_id: "0001", position: 0})
    b = routine_exercise_fixture(routine, %{exercise_id: "0002", position: 1})
    {plan, routine, a, b}
  end

  test "renders ordered exercises and the log link", %{conn: conn, user: user} do
    {plan, routine, a, b} = routine_with_exercises(user)
    routine_set_fixture(a, %{reps_min: 8, reps_max: 12, rest_seconds: 90})

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}")

    assert has_element?(lv, "#routine-exercise-#{a.id}")
    assert has_element?(lv, "#routine-exercise-#{b.id}")
    assert has_element?(lv, "a", "Log a session")
    assert render(lv) =~ "8–12 reps"
  end

  test "owner can reorder exercises with move_down", %{conn: conn, user: user} do
    {plan, routine, a, b} = routine_with_exercises(user)

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}")

    lv
    |> element("#routine-exercise-#{a.id} button[phx-click=move_down]")
    |> render_click()

    assert Gymrat.Repo.reload(a).position == 1
    assert Gymrat.Repo.reload(b).position == 0
  end

  test "owner can delete the routine", %{conn: conn, user: user} do
    {plan, routine, _a, _b} = routine_with_exercises(user)

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}")

    render_click(lv, "delete_routine")

    assert_redirect(lv, ~p"/plans/#{plan.id}")
    assert is_nil(Gymrat.Repo.reload(routine).deleted_at) == false
  end

  test "non-owner does not see edit/delete controls", %{conn: conn} do
    owner = training_user_fixture()
    {plan, routine, _a, _b} = routine_with_exercises(owner)

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}")

    refute has_element?(lv, "button[phx-click=edit_routine]")
    refute has_element?(lv, "button[phx-click=show_modal]")
  end
end
