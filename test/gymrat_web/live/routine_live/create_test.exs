defmodule GymratWeb.RoutineLive.CreateTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  alias Gymrat.Training.Routines

  setup :register_and_log_in_user

  test "creates a routine and redirects to its details", %{conn: conn, user: user} do
    plan = plan_fixture(user)

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/new")

    assert has_element?(lv, "#routine_form")

    lv
    |> form("#routine_form", routine: %{name: "Push A"})
    |> render_submit()

    [routine] = Routines.list_plan_routines(plan.id)
    assert routine.name == "Push A"
    assert_redirect(lv, ~p"/plans/#{plan.id}/routines/#{routine.id}")
  end

  test "persists selected weekdays", %{conn: conn, user: user} do
    plan = plan_fixture(user)

    {:ok, lv, _html} = live(conn, ~p"/plans/#{plan.id}/routines/new")

    lv
    |> form("#routine_form", routine: %{name: "Push A", selected_weekdays: ["1", "5"]})
    |> render_submit()

    [routine] = Routines.list_plan_routines(plan.id)

    assert Enum.sort(Enum.map(Routines.get_routine_weekdays(routine.id), & &1.weekday)) == [1, 5]
  end

  test "requires authentication" do
    conn = Phoenix.ConnTest.build_conn()

    assert {:error, {:redirect, %{to: "/users/log-in"}}} =
             live(conn, ~p"/plans/1/routines/new")
  end
end
