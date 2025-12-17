defmodule GymratWeb.ExerciseLive.Edit do
  use GymratWeb, :live_view

  alias Gymrat.Training.WorkoutExercises
  import GymratWeb.MyComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}/workouts/#{@workout_id}/exercises/#{@exercise_id}"}
        title="Edit Custom Exercise"
      />

      <div class="mx-auto max-w-sm">
        <.form for={@form} id="custom_exercise_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:custom_name]}
            type="text"
            label="Name"
            placeholder="Enter exercise name"
            required
            phx-mounted={JS.focus()}
          />

          <.input
            field={@form[:custom_description]}
            type="text"
            label="Description"
            placeholder="Enter exercise description"
            required
            phx-mounted={JS.focus()}
          />

          <.input
            field={@form[:custom_image_url]}
            type="text"
            label="Image URL"
            placeholder="Enter image URL"
            required
            phx-mounted={JS.focus()}
          />

          <div class="flex w-full flex-col">
            <.button phx-disable-with="Creating exercise..." class="btn btn-primary w-full">
              Create Exercise
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        %{"plan_id" => plan_id, "workout_id" => workout_id, "exercise_id" => exercise_id},
        _session,
        socket
      ) do
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)
    workout_exercise_id = String.to_integer(exercise_id)

    fetched_workout_exercise = WorkoutExercises.get_workout_exercise(workout_exercise_id)

    case fetched_workout_exercise do
      {:ok, workout_exercise} ->
        changeset = WorkoutExercises.change_workout_exercise(workout_exercise)

        socket =
          socket
          |> assign(:workout_exercise, workout_exercise)
          |> assign(plan_id: plan_id)
          |> assign(workout_id: workout_id)
          |> assign(exercise_id: workout_exercise_id)
          |> assign_form(changeset)

        {:ok, socket}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @impl true
  def handle_event("save", %{"custom_exercise" => exercise_params}, socket) do
    exercise_params = Map.put(exercise_params, "workout_id", socket.assigns.workout_id)
    workout_exercise = socket.assigns.workout_exercise

    case WorkoutExercises.update_workout_exercise(workout_exercise, exercise_params) do
      {:ok, updated_exercise} ->
        {:noreply,
         socket
         |> put_flash(:info, "The exercise was updated!")
         |> push_navigate(
           to:
             ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{updated_exercise.id}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"custom_exercise" => exercise_params}, socket) do
    changeset =
      WorkoutExercises.change_workout_exercise(socket.assigns.workout_exercise, exercise_params)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "custom_exercise")
    assign(socket, form: form)
  end
end
