defmodule GymratWeb.WorkoutLive.Index do
  use GymratWeb, :live_view
  alias Gymrat.Training

  def mount(_params, _session, socket) do
    # `current_user` is already assigned by the on_mount hook
    workouts = Training.list_workouts()
    {:ok, assign(socket, workouts: workouts)}
  end

  def handle_event("save", %{"workout" => workout_params}, socket) do
    # Access the user from the socket's assigns
    if socket.assigns.current_user do
      workout_params = Map.put(workout_params, "creator_id", socket.assigns.current_user.id)

      case Training.create_workout(workout_params) do
        {:ok, workout} ->
          {:noreply,
           assign(socket,
             workouts: [workout | socket.assigns.workouts],
             new_workout: %{}
           )}

        {:error, changeset} ->
          {:noreply, assign(socket, :error, changeset)}
      end
    else
      IO.puts("No user is logged in")
      # Handle case where no user is logged in
      {:noreply, socket}
    end
  end
end
