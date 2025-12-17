defmodule GymratWeb.ExerciseLive.AddCustom do
  use GymratWeb, :live_view

  alias Gymrat.Training.WorkoutExercises
  import GymratWeb.MyComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}/workouts/#{@workout_id}"}
        title="Add Custom Exercise"
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
  def mount(%{"plan_id" => plan_id, "workout_id" => workout_id}, _session, socket) do
    changeset = WorkoutExercises.change_workout_exercise_map(%{})

    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)

    socket =
      socket
      |> assign_form(changeset)
      |> assign(plan_id: plan_id)
      |> assign(workout_id: workout_id)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"custom_exercise" => exercise_params}, socket) do
    exercise_params = Map.put(exercise_params, "workout_id", socket.assigns.workout_id)

    case WorkoutExercises.create_workout_exercise(exercise_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "The exercise was created!")
         |> push_navigate(
           to: ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}"
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"custom_exercise" => exercise_params}, socket) do
    changeset = WorkoutExercises.change_workout_exercise_map(exercise_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "custom_exercise")
    assign(socket, form: form)
  end
end
