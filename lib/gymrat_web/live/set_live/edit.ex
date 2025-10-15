defmodule GymratWeb.SetLive.Edit do
  use GymratWeb, :live_view

  alias Gymrat.Training.Sets
  import GymratWeb.MyComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}/workouts/#{@workout_id}/exercises/#{@exercise_id}"}
        title="Update Set"
      />

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

          <.button phx-disable-with="Updating set..." class="btn btn-primary w-full">
            Update the Set
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        %{
          "plan_id" => plan_id,
          "workout_id" => workout_id,
          "exercise_id" => exercise_id,
          "set_id" => set_id
        },
        _session,
        socket
      ) do
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)
    exercise_id = String.to_integer(exercise_id)
    set_id = String.to_integer(set_id)

    fetched_set = Sets.get_set(set_id)

    case fetched_set do
      {:ok, set} ->
        changeset = Sets.change_set(set)

        socket =
          socket
          |> assign(plan_id: plan_id, workout_id: workout_id, exercise_id: exercise_id, set: set)
          |> assign_form(changeset)

        {:ok, socket}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @impl true
  def handle_event("save", %{"set" => set_params}, socket) do
    set = socket.assigns.set

    case Sets.update_set(set, set_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The set was updated!"
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
    set = socket.assigns.set
    changeset = Sets.change_set(set, set_params)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "set")
    assign(socket, :form, form)
  end
end
