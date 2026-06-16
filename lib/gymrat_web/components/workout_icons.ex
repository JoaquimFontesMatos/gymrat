defmodule GymratWeb.WorkoutIcons do
  @moduledoc """
  Body-map gym icon set for workouts.

  Each muscle icon is the same human figure (front or back) with the target
  muscle group highlighted, so they read as one coherent set. The figure data
  comes from the MIT-licensed body-highlighter project
  (https://github.com/HichamELBSI/react-native-body-highlighter), pre-parsed into
  `priv/workout_body_icons.json`. `"dumbbell"` (Lucide, ISC) is the generic
  fallback for custom/empty workouts.

  A workout's icon is resolved with `resolve_icon/1`:

    1. an explicit `workout.icon` override (chosen on the workout form), else
    2. the icon for the most common primary muscle of its exercises
       (`body_part`, ties broken by the first exercise added), else
    3. `"dumbbell"`.
  """
  use Phoenix.Component

  @body_data_path Path.expand("../../../priv/workout_body_icons.json", __DIR__)
  @external_resource @body_data_path
  @body @body_data_path |> File.read!() |> Jason.decode!()

  @front_base @body["front_base"]
  @back_base @body["back_base"]
  # name => %{"side" => "front"|"back", "hi" => highlight path markup}
  @body_icons @body["icons"]

  @front_box "0 0 724 1448"
  @back_box "724 0 724 1448"

  @dumbbell ~S(<path d="M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828l-1.767-1.768a2 2 0 1 0-2.829 2.829z"/><path d="m2.5 21.5 1.4-1.4"/><path d="m20.1 3.9 1.4-1.4"/><path d="M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829l1.768 1.767a2 2 0 0 0-2.828 2.829z"/><path d="m9.6 14.4 4.8-4.8"/>)

  # Free-exercise-db primaryMuscles (see exercise_live/add.ex) => icon name.
  @muscle_to_icon %{
    "chest" => "chest",
    "biceps" => "biceps",
    "triceps" => "triceps",
    "forearms" => "forearm",
    "shoulders" => "shoulders",
    "traps" => "traps",
    "neck" => "shoulders",
    "abdominals" => "abs",
    "lats" => "back",
    "middle back" => "back",
    "lower back" => "back",
    "quadriceps" => "quads",
    "adductors" => "quads",
    "abductors" => "quads",
    "hamstrings" => "hamstrings",
    "glutes" => "glutes",
    "calves" => "calves"
  }

  # Order shown in the workout form's icon picker (head-to-toe, front then back).
  @order ~w(dumbbell chest shoulders traps biceps triceps forearm abs obliques quads calves hamstrings glutes back)

  @doc "Icon names for the picker grid, in display order."
  def icon_names, do: @order

  @doc "Maps a free-exercise-db primary muscle to an icon name (or nil)."
  def muscle_to_icon(nil), do: nil

  def muscle_to_icon(muscle) when is_binary(muscle) do
    Map.get(@muscle_to_icon, muscle |> String.downcase() |> String.replace("_", " "))
  end

  def muscle_to_icon(_), do: nil

  @doc """
  Resolves the icon for a workout: explicit override, else the dominant
  muscle of its (preloaded) exercises, else `"dumbbell"`.
  """
  def resolve_icon(%{icon: icon}) when is_binary(icon) and icon != "", do: icon

  def resolve_icon(%{workout_exercises: exercises}) when is_list(exercises),
    do: dominant_icon(exercises)

  def resolve_icon(%{routine_exercises: exercises}) when is_list(exercises),
    do: dominant_icon(exercises)

  def resolve_icon(_), do: "dumbbell"

  defp dominant_icon(exercises) do
    parts =
      exercises
      |> Enum.map(&body_part_of/1)
      |> Enum.reject(&is_nil/1)

    case parts do
      [] ->
        "dumbbell"

      _ ->
        freq = Enum.frequencies(parts)
        # uniq preserves first-seen order; max_by keeps the first on ties.
        dominant = parts |> Enum.uniq() |> Enum.max_by(&Map.fetch!(freq, &1))
        muscle_to_icon(dominant) || "dumbbell"
    end
  end

  @doc """
  Resolves the icon for a single exercise from its `body_part` (or a provider
  primary-muscle string), falling back to `"dumbbell"` for custom exercises.
  """
  def exercise_icon(%{body_part: body_part}), do: exercise_icon(body_part)
  def exercise_icon(muscle) when is_binary(muscle), do: muscle_to_icon(muscle) || "dumbbell"
  def exercise_icon(_), do: "dumbbell"

  defp body_part_of(%{body_part: body_part}), do: body_part
  defp body_part_of(_), do: nil

  @doc """
  Renders a workout icon by name.

  Muscle names render a human figure with the muscle highlighted; any other
  (or nil) name renders the dumbbell glyph.
  """
  attr :name, :string, default: nil
  attr :class, :string, default: "size-[1.2em]"
  attr :rest, :global

  def workout_icon(assigns) do
    assigns =
      case Map.get(@body_icons, assigns.name || "dumbbell") do
        %{"side" => side, "hi" => hi} ->
          base = if side == "front", do: @front_base, else: @back_base
          box = if side == "front", do: @front_box, else: @back_box
          assign(assigns, body?: true, hi: hi, base: base, box: box)

        _ ->
          assign(assigns, body?: false, glyph: @dumbbell)
      end

    ~H"""
    <svg
      :if={@body?}
      xmlns="http://www.w3.org/2000/svg"
      viewBox={@box}
      fill="currentColor"
      class={@class}
      {@rest}
    >
      <g class="opacity-20">{Phoenix.HTML.raw(@base)}</g>
      <g>{Phoenix.HTML.raw(@hi)}</g>
    </svg>
    <svg
      :if={!@body?}
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1"
      stroke-linecap="round"
      stroke-linejoin="round"
      class={@class}
      {@rest}
    >{Phoenix.HTML.raw(@glyph)}</svg>
    """
  end
end
