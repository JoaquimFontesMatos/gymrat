defmodule GymratWeb.RoutineExerciseLive.DetailsTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  alias Gymrat.Training.RoutineSets

  setup :register_and_log_in_user

  defp exercise_for(user) do
    plan = plan_fixture(user)
    routine = routine_fixture(plan)
    {plan, routine, routine_exercise_fixture(routine)}
  end

  test "owner can add a planned set", %{conn: conn, user: user} do
    {plan, routine, exercise} = exercise_for(user)

    {:ok, lv, _html} =
      live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/exercises/#{exercise.id}")

    lv
    |> form("#new_set_form", set: %{reps_min: 8, reps_max: 12, rest_seconds: 120})
    |> render_submit()

    assert [set] = RoutineSets.list_routine_sets(exercise.id)
    assert set.reps_min == 8
    assert set.reps_max == 12
    assert has_element?(lv, "#routine-set-#{set.id}")
  end

  test "owner can delete a planned set", %{conn: conn, user: user} do
    {plan, routine, exercise} = exercise_for(user)
    set = routine_set_fixture(exercise)

    {:ok, lv, _html} =
      live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/exercises/#{exercise.id}")

    lv
    |> element("#routine-set-#{set.id} button[phx-click=delete_set]")
    |> render_click()

    assert RoutineSets.list_routine_sets(exercise.id) == []
  end

  test "non-owner sees read-only sets without the add form", %{conn: conn} do
    owner = training_user_fixture()
    {plan, routine, exercise} = exercise_for(owner)
    routine_set_fixture(exercise, %{reps_min: 5})

    {:ok, lv, _html} =
      live(conn, ~p"/plans/#{plan.id}/routines/#{routine.id}/exercises/#{exercise.id}")

    refute has_element?(lv, "#new_set_form")
    assert render(lv) =~ "5"
  end
end
