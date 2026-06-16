defmodule GymratWeb.RoutineLive.PerformTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  alias Gymrat.Training.RoutineSetLogs

  setup :register_and_log_in_user

  defp routine_with_set(user) do
    plan = plan_fixture(user)
    routine = routine_fixture(plan)
    exercise = routine_exercise_fixture(routine)
    {plan, routine, routine_set_fixture(exercise, %{reps_min: 10})}
  end

  test "logs actual performance for a planned set", %{conn: conn, user: user} do
    {plan, routine, set} = routine_with_set(user)

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    assert has_element?(lv, "#perform-set-form-#{set.id}")

    lv
    |> form("#perform-set-form-#{set.id}", log: %{reps: 9, weight: 55.0})
    |> render_submit()

    log = RoutineSetLogs.todays_logs_by_set([set.id], user.id)[set.id]
    assert log.reps == 9
    assert log.weight == 55.0
  end

  test "re-logging updates today's existing log", %{conn: conn, user: user} do
    {plan, routine, set} = routine_with_set(user)

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    form_selector = "#perform-set-form-#{set.id}"

    lv |> form(form_selector, log: %{reps: 9, weight: 55.0}) |> render_submit()
    lv |> form(form_selector, log: %{reps: 11, weight: 60.0}) |> render_submit()

    logs =
      RoutineSetLogs.todays_logs_by_set([set.id], user.id)
      |> Map.values()

    assert length(logs) == 1
    assert hd(logs).reps == 11
  end
end
