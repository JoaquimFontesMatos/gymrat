defmodule GymratWeb.RoutineLive.Create do
  use GymratWeb, :live_view

  alias Gymrat.Training.Routines
  import GymratWeb.MyComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate navigate={~p"/plans/#{@plan_id}"} title="Add Routine" />

      <div class="mx-auto max-w-sm">
        <.form for={@form} id="routine_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:name]}
            type="text"
            label="Routine Name"
            placeholder="Push Day A"
            required
            phx-mounted={JS.focus()}
          />

          <fieldset class="mt-4">
            <legend class="text-gray-400 text-xs">Icon (defaults to your exercises)</legend>
            <div class="gap-2 grid grid-cols-3 sm:grid-cols-4 mt-1">
              <label class="flex flex-col justify-center items-center has-[:checked]:bg-primary/20 p-1 border has-[:checked]:border-primary rounded cursor-pointer">
                <input
                  type="radio"
                  name="routine[icon]"
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
                  name="routine[icon]"
                  value={name}
                  class="sr-only"
                  checked={@form[:icon].value == name}
                />
                <.workout_icon name={name} class="w-10 h-14 text-primary" />
                <span class="text-[10px] text-gray-500 capitalize">{name}</span>
              </label>
            </div>
          </fieldset>

          <.button phx-disable-with="Creating routine..." class="mt-4 w-full btn btn-primary">
            Create a Routine
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => plan_id}, _session, socket) do
    changeset = Routines.change_routine_map(%{})
    plan_id = String.to_integer(plan_id)

    socket =
      socket
      |> assign_form(changeset)
      |> assign(plan_id: plan_id)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"routine" => routine_params}, socket) do
    routine_params = Map.put(routine_params, "plan_id", socket.assigns.plan_id)

    case Routines.create_routine(routine_params) do
      {:ok, routine} ->
        {:noreply,
         socket
         |> put_flash(:info, "The routine was created!")
         |> push_navigate(to: ~p"/plans/#{socket.assigns.plan_id}/routines/#{routine.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"routine" => routine_params}, socket) do
    changeset = Routines.change_routine_map(routine_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: "routine"))
  end
end
