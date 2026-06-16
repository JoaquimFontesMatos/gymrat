defmodule GymratWeb.WorkoutLive.Create do
  use GymratWeb, :live_view

  alias Gymrat.Training.Workouts
  import GymratWeb.MyComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}"}
        title="Add Workout"
      />

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

          <fieldset class="mt-4">
            <legend class="text-gray-400 text-xs">Icon (defaults to your exercises)</legend>
            <div class="gap-2 grid grid-cols-3 sm:grid-cols-4 mt-1">
              <label class="flex flex-col justify-center items-center has-[:checked]:bg-primary/20 p-1 border has-[:checked]:border-primary rounded cursor-pointer">
                <input
                  type="radio"
                  name="workout[icon]"
                  value=""
                  class="sr-only"
                  checked={(@form[:icon].value || "") == ""}
                />
                <span class="text-sm">Auto</span>
              </label>
              <label
                :for={name <- icon_names()}
                class="flex flex-col items-center gap-1 has-[:checked]:bg-primary/20 p-1 border has-[:checked]:border-primary rounded cursor-pointer"
              >
                <input
                  type="radio"
                  name="workout[icon]"
                  value={name}
                  class="sr-only"
                  checked={@form[:icon].value == name}
                />
                <.workout_icon name={name} class="w-10 h-14 text-primary" />
                <span class="text-[10px] text-gray-500 capitalize">{name}</span>
              </label>
            </div>
          </fieldset>

          <.weekday_picker field={@form[:selected_weekdays]} label="Days to schedule" />

          <.button phx-disable-with="Creating workout..." class="mt-4 w-full btn btn-primary">
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

    if normalized_weekdays == [] do
      changeset =
        workout_params
        |> Map.put("selected_weekdays", [])
        |> Workouts.change_workout_map()
        |> Map.put(:action, :validate)

      {:noreply, assign_form(socket, changeset)}
    else
      case Workouts.create_workout_with_weekdays(
             Map.delete(workout_params, "selected_weekdays"),
             normalized_weekdays
           ) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "The workout was created!")
           |> push_navigate(to: ~p"/plans/#{socket.assigns.plan_id}")}

        {:error, %Ecto.Changeset{} = changeset} ->
          changeset =
            Ecto.Changeset.put_change(changeset, :selected_weekdays, normalized_weekdays)

          {:noreply, assign_form(socket, changeset)}
      end
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
