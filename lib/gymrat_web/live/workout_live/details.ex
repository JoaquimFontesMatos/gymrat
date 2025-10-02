defmodule GymratWeb.WorkoutLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.Workouts

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
            <a
              :if={@is_workout_owner}
              class="underline hover:text-blue-500"
              href={~p"/plans/#{@plan_id}/workouts/#{@workout.id}/exercises/new"}
            >
              Add one!
            </a>
          </p>
        <% else %>
          <.button :if={@is_workout_owner} phx-click="add_exercise" class="btn btn-primary w-full">
            Add an Exercise
          </.button>
        <% end %>
      </ul>

      <div class="flex justify-end flex-wrap gap-4">
        <.button :if={@is_workout_owner} phx-click="update_workout">
          Update
        </.button>

        <.button :if={@is_workout_owner} class="btn btn-error" phx-click="show_modal">
          Delete
        </.button>

        <.modal
          :if={@show_modal}
          id="confirm-modal"
          on_cancel={JS.push("hide_modal")}
        >
          <h2>Are you sure you want to delete this workout?</h2>
          <p>This action cannot be undone.</p>
          <div class="modal-action">
            <.button phx-click="hide_modal">
              Cancel
            </.button>
            <.button class="btn btn-error" phx-click="delete_workout">
              Confirm
            </.button>
          </div>
        </.modal>
      </div>

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
    user_id = socket.assigns.current_scope.user.id

    isWorkoutOwner = Workouts.is_workout_from_user(workout_id, user_id)

    case Workouts.get_workout(workout_id) do
      {:ok, workout} ->
        {:ok,
         assign(socket,
           plan_id: plan_id,
           workout: workout,
           show_modal: false,
           is_workout_owner: isWorkoutOwner
         )}

      {:error, _reason} ->
        {:error, :not_found}
    end
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

  # Event to show the modal
  @impl true
  def handle_event("show_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  # Event to hide the modal
  @impl true
  def handle_event("hide_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
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

  @impl true
  def handle_event("update_workout", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to: ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout.id}/edit"
      )
    }
  end

  @impl true
  def handle_event("delete_workout", _payload, socket) do
    case Workouts.soft_delete_workout(socket.assigns.workout) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The workout was deleted!"
          )
          |> push_navigate(to: ~p"/plans/#{socket.assigns.plan_id}")
        }

      {:error, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :error,
            "Failed to delete the workout!"
          )
        }
    end
  end
end
