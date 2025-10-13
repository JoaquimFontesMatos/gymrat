defmodule GymratWeb.WorkoutLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.Workouts

  defp get_localized_weekdays(weekdays) when is_list(weekdays) do
    case weekdays do
      [] ->
        "No weekday"

      _ ->
        weekdays
        |> Enum.map(&weekday_to_string(&1.weekday))
        |> Enum.join(", ")
    end
  end

  defp weekday_to_string(weekday) do
    case weekday do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
      _ -> "No weekday"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex gap-4">
        <.button
          class="btn-soft btn-square stroke"
          phx-click="back_to_plan"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="size-[1.2em] fill-primary"
          >
            <path
              fill-rule="evenodd"
              d="M9.53 2.47a.75.75 0 0 1 0 1.06L4.81 8.25H15a6.75 6.75 0 0 1 0 13.5h-3a.75.75 0 0 1 0-1.5h3a5.25 5.25 0 1 0 0-10.5H4.81l4.72 4.72a.75.75 0 1 1-1.06 1.06l-6-6a.75.75 0 0 1 0-1.06l6-6a.75.75 0 0 1 1.06 0Z"
              clip-rule="evenodd"
            />
          </svg>
        </.button>
        <h1 class="text-2xl font-bold">{@workout.name}</h1>
      </div>

      <div class="flex items-center gap-2">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          class="size-[1.2em] fill-primary/50"
        >
          <path
            fill-rule="evenodd"
            d="M6.75 2.25A.75.75 0 0 1 7.5 3v1.5h9V3A.75.75 0 0 1 18 3v1.5h.75a3 3 0 0 1 3 3v11.25a3 3 0 0 1-3 3H5.25a3 3 0 0 1-3-3V7.5a3 3 0 0 1 3-3H6V3a.75.75 0 0 1 .75-.75Zm13.5 9a1.5 1.5 0 0 0-1.5-1.5H5.25a1.5 1.5 0 0 0-1.5 1.5v7.5a1.5 1.5 0 0 0 1.5 1.5h13.5a1.5 1.5 0 0 0 1.5-1.5v-7.5Z"
            clip-rule="evenodd"
          />
        </svg>

        <span class="text-gray-500">
          {get_localized_weekdays(Workouts.get_workout_weekdays(@workout.id))}
        </span>
      </div>
      <ul>
        <%= for exercise <- @workout.workout_exercises do %>
          <li>
            <.button
              class="mb-2 border rounded flex justify-between items-center group w-full"
              phx-click="go_to_exercise"
              phx-value-exercise-id={exercise.id}
              tabindex="0"
            >
              <span class="p-2">
                {exercise.exercise_id
                |> String.replace("_", " ")
                |> String.capitalize()}
              </span>
              <span class="p-4 opacity-0 w-0 group-active:bg-primary/50 group-active:opacity-100 group-active:w-[35%] group-hover:bg-primary/50 group-hover:opacity-100 group-hover:w-[35%] group-focus:bg-primary/50 group-focus:opacity-100 group-focus:w-[35%] transition-all duration-300 ease-in-out overflow-hidden">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  class="size-6"
                >
                  <path
                    fill-rule="evenodd"
                    d="M12.97 3.97a.75.75 0 0 1 1.06 0l7.5 7.5a.75.75 0 0 1 0 1.06l-7.5 7.5a.75.75 0 1 1-1.06-1.06l6.22-6.22H3a.75.75 0 0 1 0-1.5h16.19l-6.22-6.22a.75.75 0 0 1 0-1.06Z"
                    clip-rule="evenodd"
                  />
                </svg>
              </span>
            </.button>
          </li>
        <% end %>

        <%= if Enum.empty?(@workout.workout_exercises) do %>
          <p>
            No exercises added yet.
            <a
              :if={@is_workout_owner}
              class="underline hover:text-secondary"
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

      <div class="flex justify-end flex-wrap gap-2">
        <.button
          :if={@is_workout_owner}
          phx-click="update_workout"
          class="btn btn-primary btn-soft btn-square"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="size-[1.2em]"
          >
            <path d="M21.731 2.269a2.625 2.625 0 0 0-3.712 0l-1.157 1.157 3.712 3.712 1.157-1.157a2.625 2.625 0 0 0 0-3.712ZM19.513 8.199l-3.712-3.712-12.15 12.15a5.25 5.25 0 0 0-1.32 2.214l-.8 2.685a.75.75 0 0 0 .933.933l2.685-.8a5.25 5.25 0 0 0 2.214-1.32L19.513 8.2Z" />
          </svg>
        </.button>

        <.button
          :if={@is_workout_owner}
          class="btn btn-error btn-soft btn-square"
          phx-click="show_modal"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="size-[1.2em]"
          >
            <path
              fill-rule="evenodd"
              d="M16.5 4.478v.227a48.816 48.816 0 0 1 3.878.512.75.75 0 1 1-.256 1.478l-.209-.035-1.005 13.07a3 3 0 0 1-2.991 2.77H8.084a3 3 0 0 1-2.991-2.77L4.087 6.66l-.209.035a.75.75 0 0 1-.256-1.478A48.567 48.567 0 0 1 7.5 4.705v-.227c0-1.564 1.213-2.9 2.816-2.951a52.662 52.662 0 0 1 3.369 0c1.603.051 2.815 1.387 2.815 2.951Zm-6.136-1.452a51.196 51.196 0 0 1 3.273 0C14.39 3.05 15 3.684 15 4.478v.113a49.488 49.488 0 0 0-6 0v-.113c0-.794.609-1.428 1.364-1.452Zm-.355 5.945a.75.75 0 1 0-1.5.058l.347 9a.75.75 0 1 0 1.499-.058l-.346-9Zm5.48.058a.75.75 0 1 0-1.498-.058l-.347 9a.75.75 0 0 0 1.5.058l.345-9Z"
              clip-rule="evenodd"
            />
          </svg>
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
