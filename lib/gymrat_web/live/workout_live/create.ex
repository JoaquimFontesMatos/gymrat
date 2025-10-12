defmodule GymratWeb.WorkoutLive.Create do
  use GymratWeb, :live_view

  alias Gymrat.Training.Workouts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">Add Workout</h1>

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

          <label class="mt-4 text-xs text-gray-400">Days to schedule:</label>
          <.input
            field={@form[:selected_weekdays]}
            type="select"
            label="Weekdays"
            class="select w-full"
            multiple
            options={[
              {"Monday", 1},
              {"Tuesday", 2},
              {"Wednesday", 3},
              {"Thursday", 4},
              {"Friday", 5},
              {"Saturday", 6},
              {"Sunday", 7}
            ]}
            required
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
    changeset = Workouts.change_workout_map(%{selected_weekdays: []})
    plan_id = String.to_integer(plan_id)

    socket =
      socket
      |> assign_form(changeset)
      |> assign(plan_id: plan_id)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"workout" => workout_params}, socket) do
    weekdays = Map.get(workout_params, "selected_weekdays", [])

    normalized_weekdays =
      if(is_nil(weekdays), do: [], else: weekdays)
      |> Enum.map(&String.to_integer/1)

    workout_params = Map.put(workout_params, "plan_id", socket.assigns.plan_id)

    workout_params = Map.delete(workout_params, "selected_weekdays")

    case Workouts.create_workout_with_weekdays(workout_params, normalized_weekdays) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "The workout was created!")
         |> push_navigate(to: ~p"/plans/#{socket.assigns.plan_id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        changeset = Ecto.Changeset.put_change(changeset, :selected_weekdays, normalized_weekdays)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"workout" => workout_params}, socket) do
    weekdays = Map.get(workout_params, "selected_weekdays", [])

    normalized_weekdays =
      if(is_nil(weekdays), do: [], else: weekdays)
      |> Enum.map(&String.to_integer/1)

    workout_params = Map.put(workout_params, "selected_weekdays", normalized_weekdays)

    changeset = Workouts.change_workout_map(workout_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "workout")
    assign(socket, form: form)
  end
end
