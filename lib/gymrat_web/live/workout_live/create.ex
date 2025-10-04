defmodule GymratWeb.WorkoutLive.Create do
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
            placeholder="Leg Day"
            required
            phx-mounted={JS.focus()}
          />

          <.input
            field={@form[:weekday]}
            type="select"
            label="Weekday"
            options={[
              {"No weekday", nil},
              {"Monday", 1},
              {"Tuesday", 2},
              {"Wednesday", 3},
              {"Thursday", 4},
              {"Friday", 5},
              {"Saturday", 6},
              {"Sunday", 7}
            ]}
          />

          <.button phx-disable-with="Creating workout..." class="btn btn-primary w-full">
            Create an Workout
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => plan_id}, _session, socket) do
    changeset = Workouts.change_workout_map(%{})
    plan_id = String.to_integer(plan_id)

    socket =
      socket
      # Call your helper function to assign :form
      |> assign_form(changeset)
      # Assign the plan_id to the socket as @plan_id
      |> assign(plan_id: plan_id)

    # temporary_assigns should typically be for specific LiveView cases
    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"workout" => workout_params}, socket) do
    workout_params = Map.put(workout_params, "plan_id", socket.assigns.plan_id)

    case Workouts.create_workout(workout_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The workout was created!"
          )
          |> push_navigate(to: ~p"/plans/#{socket.assigns.plan_id}")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"workout" => workout_params}, socket) do
    changeset = Workouts.change_workout_map(workout_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "workout")
    assign(socket, form: form)
  end
end
