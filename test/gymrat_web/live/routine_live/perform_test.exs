defmodule GymratWeb.RoutineLive.PerformTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  alias Gymrat.Training.RoutineSetLogs

  setup :register_and_log_in_user

  # Builds plan → routine → one exercise with the given planned sets (in order).
  defp routine_with_sets(user, set_attrs_list) do
    plan = plan_fixture(user)
    routine = routine_fixture(plan)
    exercise = routine_exercise_fixture(routine)

    sets =
      set_attrs_list
      |> Enum.with_index()
      |> Enum.map(fn {attrs, i} ->
        routine_set_fixture(exercise, Map.put(attrs, :position, i))
      end)

    {plan, routine, sets}
  end

  defp todays_log(set, user), do: RoutineSetLogs.todays_logs_by_set([set.id], user.id)[set.id]

  test "starts on the first set, prefilled with the target reps", %{conn: conn, user: user} do
    {plan, routine, _sets} =
      routine_with_sets(user, [%{reps_min: 10, rest_seconds: 90}, %{reps_min: 8, rest_seconds: 0}])

    {:ok, lv, html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    assert has_element?(lv, "#guided-set-form")
    assert html =~ "Set 1 of 2"
    assert html =~ "target 10"
    assert has_element?(lv, "#guided-log_reps[value=\"10\"]")
  end

  test "logging a set persists it and shows the rest screen", %{conn: conn, user: user} do
    {plan, routine, [set1, _set2]} =
      routine_with_sets(user, [%{reps_min: 10, rest_seconds: 90}, %{reps_min: 8, rest_seconds: 0}])

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    lv |> form("#guided-set-form", log: %{reps: 9, weight: 55.0}) |> render_submit()

    log = todays_log(set1, user)
    assert log.reps == 9
    assert log.weight == 55.0
    assert has_element?(lv, "#rest-timer")
  end

  test "advancing past rest shows the next set", %{conn: conn, user: user} do
    {plan, routine, _sets} =
      routine_with_sets(user, [%{reps_min: 10, rest_seconds: 90}, %{reps_min: 8, rest_seconds: 0}])

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    lv |> form("#guided-set-form", log: %{reps: 9, weight: 55.0}) |> render_submit()
    assert has_element?(lv, "#rest-timer")

    html = render_click(lv, "next")
    assert html =~ "Set 2 of 2"
  end

  test "skipping a set advances without creating a log", %{conn: conn, user: user} do
    {plan, routine, [set1, _set2]} =
      routine_with_sets(user, [%{reps_min: 10, rest_seconds: 90}, %{reps_min: 8, rest_seconds: 0}])

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    html = render_click(lv, "skip")

    assert html =~ "Set 2 of 2"
    assert RoutineSetLogs.todays_logs_by_set([set1.id], user.id) == %{}
  end

  test "logging the only set ends the session", %{conn: conn, user: user} do
    {plan, routine, _sets} = routine_with_sets(user, [%{reps_min: 5, rest_seconds: 0}])

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    html = lv |> form("#guided-set-form", log: %{reps: 5, weight: 40.0}) |> render_submit()

    assert html =~ "Session complete"
    refute has_element?(lv, "#guided-set-form")
  end

  test "resumes at the first unlogged set on fresh entry", %{conn: conn, user: user} do
    {plan, routine, [set1, _set2]} =
      routine_with_sets(user, [%{reps_min: 10, rest_seconds: 90}, %{reps_min: 8, rest_seconds: 0}])

    routine_set_log_fixture(user, set1, %{reps: 10, weight: 50.0})

    {:ok, _lv, html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    assert html =~ "Set 2 of 2"
  end

  test "restores the exact step/phase from the URL after a reload", %{conn: conn, user: user} do
    {plan, routine, _sets} =
      routine_with_sets(user, [%{reps_min: 10, rest_seconds: 90}, %{reps_min: 8, rest_seconds: 0}])

    # A reload re-hits the patched URL; the rest screen for step 0 is restored.
    {:ok, lv, html} =
      live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform?step=0&phase=rest")

    assert html =~ "Up next: set 2 of 2"
    assert has_element?(lv, "#rest-timer")
  end

  test "restarting re-runs from the first set and updates the existing log", %{
    conn: conn,
    user: user
  } do
    {plan, routine, [set1]} = routine_with_sets(user, [%{reps_min: 5, rest_seconds: 0}])

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    lv |> form("#guided-set-form", log: %{reps: 5, weight: 40.0}) |> render_submit()
    assert render(lv) =~ "Session complete"

    html = render_click(lv, "restart")
    assert html =~ "Set 1 of 1"

    lv |> form("#guided-set-form", log: %{reps: 6, weight: 45.0}) |> render_submit()

    logs = RoutineSetLogs.todays_logs_by_set([set1.id], user.id)
    assert map_size(logs) == 1
    assert logs[set1.id].reps == 6
    assert logs[set1.id].weight == 45.0
  end

  test "a time-based set shows a work timer and logs the duration", %{conn: conn, user: user} do
    {plan, routine, [set]} =
      routine_with_sets(user, [%{reps_min: nil, duration_seconds: 30, rest_seconds: 0}])

    {:ok, lv, html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    assert has_element?(lv, "#work-timer-0 button[data-rest=\"30\"]")
    assert html =~ "hold 30s"
    assert has_element?(lv, "#guided-log_duration_seconds")

    # Weight left blank — allowed for timed sets.
    html = lv |> form("#guided-set-form", log: %{duration_seconds: 25}) |> render_submit()

    log = todays_log(set, user)
    assert log.duration_seconds == 25
    assert is_nil(log.reps)
    assert is_nil(log.weight)
    assert html =~ "Session complete"
  end

  test "the info button opens the exercise details", %{conn: conn, user: user} do
    plan = plan_fixture(user)
    routine = routine_fixture(plan)
    exercise = routine_exercise_fixture(routine, %{exercise_id: nil, custom_name: "plank"})
    routine_set_fixture(exercise, %{reps_min: 10})

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    refute has_element?(lv, "#exercise-info-modal")

    lv |> element("button[phx-click=show_info]") |> render_click()

    assert has_element?(lv, "#exercise-info-modal")
    assert render(lv) =~ "Plank"
  end

  test "shows an empty state for a routine with no planned sets", %{conn: conn, user: user} do
    plan = plan_fixture(user)
    routine = routine_fixture(plan)
    _exercise = routine_exercise_fixture(routine)

    {:ok, _lv, html} = live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/perform")

    assert html =~ "no planned sets"
  end
end
