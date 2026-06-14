defmodule GymratWeb.ExerciseLive.AddTest do
  use GymratWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Gymrat.TrainingFixtures

  alias Gymrat.Training.WorkoutExercises

  setup :register_and_log_in_user

  defp workout_for(user) do
    plan = plan_fixture(user)
    {plan, workout_fixture(plan)}
  end

  defp new_exercise_path(plan, workout),
    do: ~p"/plans/#{plan.id}/workouts/#{workout.id}/exercises/new"

  test "lists exercises from the (stubbed) provider", %{conn: conn, user: user} do
    {plan, workout} = workout_for(user)

    {:ok, lv, _html} = live(conn, new_exercise_path(plan, workout))
    html = render_async(lv)

    assert html =~ "Barbell Curl"
    assert html =~ "Bench Press"
    assert has_element?(lv, "button", "Add Exercise")
  end

  test "flags exercises already in the workout as Added", %{conn: conn, user: user} do
    {plan, workout} = workout_for(user)
    workout_exercise_fixture(workout, %{exercise_id: "0001"})

    {:ok, lv, _html} = live(conn, new_exercise_path(plan, workout))
    render_async(lv)

    assert has_element?(lv, "button[disabled]", "Added")
  end

  test "re-adding an exercise already in the workout flashes instead of crashing",
       %{conn: conn, user: user} do
    {plan, workout} = workout_for(user)
    workout_exercise_fixture(workout, %{exercise_id: "0001"})

    {:ok, lv, _html} = live(conn, new_exercise_path(plan, workout))
    render_async(lv)

    html = render_click(lv, "add_exercise", %{"exercise-id" => "0001", "body-part" => "biceps"})
    assert html =~ "already in this workout"
  end

  test "adding a new exercise persists it and navigates back to the workout",
       %{conn: conn, user: user} do
    {plan, workout} = workout_for(user)

    {:ok, lv, _html} = live(conn, new_exercise_path(plan, workout))
    render_async(lv)

    render_click(lv, "add_exercise", %{"exercise-id" => "0002", "body-part" => "chest"})

    assert_redirect(lv, ~p"/plans/#{plan.id}/workouts/#{workout.id}")
    assert WorkoutExercises.added_exercise_ids(workout.id) == MapSet.new(["0002"])
  end

  test "requires authentication" do
    # Auth runs in on_mount before the LiveView loads any data, so ids are arbitrary.
    conn = Phoenix.ConnTest.build_conn()

    assert {:error, {:redirect, %{to: "/users/log-in"}}} =
             live(conn, ~p"/plans/1/workouts/1/exercises/new")
  end
end
