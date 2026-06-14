defmodule GymratWeb.ExerciseLive.DetailsTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  alias Gymrat.Training.Sets

  setup :register_and_log_in_user

  defp exercise_path(plan, workout, we),
    do: ~p"/plans/#{plan.id}/workouts/#{workout.id}/exercises/#{we.id}"

  defp chain(user, exercise_id) do
    plan = plan_fixture(user)
    workout = workout_fixture(plan)
    we = workout_exercise_fixture(workout, %{exercise_id: exercise_id})
    {plan, workout, we}
  end

  test "renders exercise details from the (stubbed) provider", %{conn: conn, user: user} do
    {plan, workout, we} = chain(user, "0001")

    {:ok, lv, _html} = live(conn, exercise_path(plan, workout, we))

    assert render_async(lv) =~ "Barbell Curl"
  end

  test "still renders (no crash) when the provider lookup fails", %{conn: conn, user: user} do
    {plan, workout, we} = chain(user, "error")

    {:ok, lv, html} = live(conn, exercise_path(plan, workout, we))

    # Page renders immediately despite the failing fetch...
    assert html =~ "Details"
    # ...and the async failure surfaces a non-blocking flash rather than crashing.
    assert render_async(lv) =~ "Your sets and history are still available."
  end

  test "shows personal records once sets are logged", %{conn: conn, user: user} do
    {plan, workout, we} = chain(user, "0001")

    {:ok, _set} =
      Sets.create_set(%{reps: 5, weight: 100.0, user_id: user.id, workout_exercise_id: we.id})

    {:ok, lv, _html} = live(conn, exercise_path(plan, workout, we))
    html = render_async(lv)

    assert html =~ "Best Set"
    assert html =~ "Est. 1RM"
  end
end
