defmodule GymratWeb.WorkoutIconsTest do
  use ExUnit.Case, async: true

  alias Gymrat.Workouts.Workout
  alias GymratWeb.WorkoutIcons

  defp ex(body_part), do: %{body_part: body_part}

  describe "muscle_to_icon/1" do
    test "maps known provider muscles to icons" do
      assert WorkoutIcons.muscle_to_icon("quadriceps") == "quads"
      assert WorkoutIcons.muscle_to_icon("hamstrings") == "hamstrings"
      assert WorkoutIcons.muscle_to_icon("triceps") == "triceps"
      assert WorkoutIcons.muscle_to_icon("lats") == "back"
      assert WorkoutIcons.muscle_to_icon("abdominals") == "abs"
    end

    test "normalizes case and underscores" do
      assert WorkoutIcons.muscle_to_icon("Middle_Back") == "back"
      assert WorkoutIcons.muscle_to_icon("middle back") == "back"
    end

    test "returns nil for unknown or nil" do
      assert WorkoutIcons.muscle_to_icon("eyebrows") == nil
      assert WorkoutIcons.muscle_to_icon(nil) == nil
    end
  end

  describe "resolve_icon/1" do
    test "uses an explicit override when present" do
      assert WorkoutIcons.resolve_icon(%{icon: "flame", workout_exercises: [ex("biceps")]}) ==
               "flame"
    end

    test "derives from the most common muscle, ties broken by first added" do
      exercises = [ex("quadriceps"), ex("quadriceps"), ex("hamstrings"), ex("abdominals")]
      assert WorkoutIcons.resolve_icon(%{icon: nil, workout_exercises: exercises}) == "quads"

      # 1-1 tie: first added wins
      assert WorkoutIcons.resolve_icon(%{
               icon: nil,
               workout_exercises: [ex("chest"), ex("biceps")]
             }) ==
               "chest"
    end

    test "ignores exercises without a body part" do
      assert WorkoutIcons.resolve_icon(%{icon: nil, workout_exercises: [ex(nil), ex("biceps")]}) ==
               "biceps"
    end

    test "falls back to dumbbell with no exercises, only custom exercises, or unloaded assoc" do
      assert WorkoutIcons.resolve_icon(%{icon: nil, workout_exercises: []}) == "dumbbell"
      assert WorkoutIcons.resolve_icon(%{icon: "", workout_exercises: [ex(nil)]}) == "dumbbell"
      # %Workout{} without preloaded exercises (Ecto NotLoaded) -> dumbbell
      assert WorkoutIcons.resolve_icon(%Workout{icon: nil}) == "dumbbell"
    end
  end

  describe "exercise_icon/1" do
    test "derives from a stored body_part struct" do
      assert WorkoutIcons.exercise_icon(%{body_part: "hamstrings"}) == "hamstrings"
      assert WorkoutIcons.exercise_icon(%{body_part: "quadriceps"}) == "quads"
    end

    test "accepts a raw provider muscle string" do
      assert WorkoutIcons.exercise_icon("lats") == "back"
    end

    test "falls back to dumbbell for custom/unknown" do
      assert WorkoutIcons.exercise_icon(%{body_part: nil}) == "dumbbell"
      assert WorkoutIcons.exercise_icon(nil) == "dumbbell"
    end
  end

  describe "workout_icon/1 component" do
    import Phoenix.LiveViewTest, only: [render_component: 2]

    test "renders an svg and falls back to dumbbell for unknown names" do
      assert render_component(&WorkoutIcons.workout_icon/1, name: "chest") =~ "<svg"
      unknown = render_component(&WorkoutIcons.workout_icon/1, name: "nope")
      dumbbell = render_component(&WorkoutIcons.workout_icon/1, name: "dumbbell")
      assert unknown == dumbbell
    end
  end
end
