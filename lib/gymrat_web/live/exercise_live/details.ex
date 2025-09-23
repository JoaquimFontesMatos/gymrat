defmodule GymratWeb.ExerciseLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1>
        {@exercise.exercise_id
        |> String.replace("_", " ")
        |> String.capitalize()}
      </h1>

      <ul class="list-disc pl-4">
        <%= for set <- @exercise.sets do %>
          <li class="mb-2 p-2 border rounded flex justify-between items-center">
            <span>
              <strong>Weight:</strong> {set.weight} kg &nbsp; | &nbsp;
              <strong>Reps:</strong> {set.reps}
            </span>
          </li>
        <% end %>

        <%= if Enum.empty?(@exercise.sets) do %>
          <p>
            No sets added yet.
            <a href={
              ~p"/plans/#{@plan_id}/workouts/#{@workout_id}/exercises/#{@exercise.id}/sets/new"
            }>
              Add one!
            </a>
          </p>
        <% else %>
          <.button phx-click="add_set" class="btn btn-primary w-full">
            Add a Set
          </.button>
        <% end %>
      </ul>

      <.button phx-click="back_to_workout">
        Back to Workout
      </.button>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        %{"plan_id" => plan_id, "workout_id" => workout_id, "exercise_id" => exercise_id},
        _session,
        socket
      ) do
    # Convert ID from URL param
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)
    exercise_id = String.to_integer(exercise_id)

    exercise = Training.get_todays_workout_exercise_with_sets(exercise_id)

    {:ok, assign(socket, plan_id: plan_id, workout_id: workout_id, exercise: exercise)}
  end

  @impl true
  def handle_event("back_to_workout", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to: ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}"
      )
    }
  end

  @impl true
  def handle_event("add_set", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to:
          ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{socket.assigns.exercise.id}/sets/new"
      )
    }
  end
end
