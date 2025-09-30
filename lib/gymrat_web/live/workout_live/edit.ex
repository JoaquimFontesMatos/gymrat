defmodule GymratWeb.WorkoutLive.Edit do
  use GymratWeb, :live_view

  alias Gymrat.Training.Workouts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.form for={@form} id="workout_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:name]}
            type="text"
            label="Workout Name"
            placeholder="Enter new workout name"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Updating workout..." class="btn btn-primary w-full">
            Update the Workout
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"plan_id" => plan_id, "workout_id" => workout_id}, _session, socket) do
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)

    fetched_workout = Workouts.get_workout(workout_id)

    case fetched_workout do
      {:ok, workout} ->
        changeset = Workouts.change_workout(workout)

        socket =
          socket
          |> assign(plan_id: plan_id, workout: workout)
          |> assign_form(changeset)

        {:ok, socket}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @impl true
  def handle_event("save", %{"workout" => workout_params}, socket) do
    workout = socket.assigns.workout

    case Workouts.update_workout(workout, workout_params) do
      {:ok, updated_workout} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The workout was updated!"
          )
          |> push_navigate(
            to: ~p"/plans/#{socket.assigns.plan_id}/workouts/#{updated_workout.id}"
          )
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"workout" => workout_params}, socket) do
    workout = socket.assigns.workout
    changeset = Workouts.change_workout(workout, workout_params)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "workout")
    assign(socket, :form, form)
  end
end
