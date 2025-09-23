defmodule GymratWeb.WorkoutLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1>{@workout.name}</h1>

      <ul class="list-disc pl-4">
        <%= for exercise <- @workout.workout_exercises do %>
          <li class="mb-2 p-2 border rounded flex justify-between items-center">
            <span>
              {exercise.exercise_id
              |> String.replace("_", " ")
              |> String.capitalize()}
            </span>
            <div>
              <.button phx-click="go_to_exercise" phx-value-exercise-id={exercise.id}>
                Details
              </.button>
            </div>
          </li>
        <% end %>

        <%= if Enum.empty?(@workout.workout_exercises) do %>
          <p>
            No exercises added yet.
            <a href={~p"/plans/#{@plan_id}/workouts/#{@workout.id}/exercises/new"}>Add one!</a>
          </p>
        <% else %>
          <.button phx-click="add_exercise" class="btn btn-primary w-full">
            Add an Exercise
          </.button>
        <% end %>
      </ul>

      <.button phx-click="back_to_plan">
        Back to Plan
      </.button>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"plan_id" => plan_id, "workout_id" => workout_id}, _session, socket) do
    # Convert ID from URL param
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)

    workout = Training.get_workout_with_exercises(workout_id)

    {:ok, assign(socket, plan_id: plan_id, workout: workout)}
  end

  @impl true
  def handle_event("back_to_plan", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(to: ~p"/plans/#{socket.assigns.plan_id}")
    }
  end

  @impl true
  def handle_event("add_exercise", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to:
          ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout.id}/exercises/new"
      )
    }
  end

  @impl true
  def handle_event("go_to_exercise", %{"exercise-id" => exercise_id}, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to:
          ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout.id}/exercises/#{exercise_id}"
      )
    }
  end
end
