defmodule GymratWeb.SetLive.Create do
  use GymratWeb, :live_view

  alias Gymrat.Training.Sets

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">Create Set</h1>

      <div class="mx-auto max-w-sm">
        <.form for={@form} id="set_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:reps]}
            type="number"
            label="Reps"
            placeholder="14"
            required
            phx-mounted={JS.focus()}
          />

          <.input
            field={@form[:weight]}
            type="number"
            label="Weight (Kg)"
            placeholder="15.0"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Creating set..." class="btn btn-primary w-full">
            Create a Set
          </.button>
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
    exercise_id = String.to_integer(exercise_id)

    changeset = Sets.change_set_map(%{})

    socket =
      socket
      # Call your helper function to assign :form
      |> assign_form(changeset)
      # Assign the plan_id to the socket as @plan_id
      |> assign(plan_id: plan_id, workout_id: workout_id, exercise_id: exercise_id)

    # temporary_assigns should typically be for specific LiveView cases
    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"set" => set_params}, socket) do
    user = socket.assigns.current_scope.user

    set_params =
      set_params
      |> Map.put("workout_exercise_id", socket.assigns.exercise_id)
      |> Map.put("user_id", user.id)

    case Sets.create_set(set_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The set was created!"
          )
          |> push_navigate(
            to:
              ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{socket.assigns.exercise_id}"
          )
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"set" => set_params}, socket) do
    changeset = Sets.change_set_map(set_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "set")
    assign(socket, form: form)
  end
end
