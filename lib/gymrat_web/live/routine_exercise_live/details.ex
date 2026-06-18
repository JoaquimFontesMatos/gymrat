defmodule GymratWeb.RoutineExerciseLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.RoutineExercises
  alias Gymrat.Training.RoutineSets
  import GymratWeb.MyComponents

  defp exercise_label(exercise) do
    (exercise.exercise_id || exercise.custom_name || "Unknown Exercise")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}/routines/#{@routine_id}"}
        title={exercise_label(@exercise)}
      />

      <div class="flex items-center gap-2">
        <.workout_icon name={exercise_icon(@exercise)} class="w-12 h-16 text-primary" />
        <p class="text-gray-500 text-sm">Planned sets, in order.</p>
      </div>

      <h2 class="font-bold text-lg mt-2">Planned Sets</h2>

      <ul id="routine-sets" phx-hook="Sortable" class="flex flex-col gap-2">
        <li
          :for={{set, index} <- Enum.with_index(@exercise.routine_sets)}
          id={"routine-set-#{set.id}"}
          data-sortable-item
          data-id={set.id}
          class="flex items-center gap-2 rounded-lg border border-base-300 p-2"
        >
          <span
            :if={@is_owner}
            data-drag-handle
            class="cursor-grab text-gray-400 hover:text-gray-600 active:cursor-grabbing shrink-0"
            aria-hidden="true"
          >
            <.icon name="hero-bars-3" class="size-4" />
          </span>
          <span class="font-semibold w-12 shrink-0">Set {index + 1}</span>

          <%= if @is_owner do %>
            <.form
              for={@set_forms[set.id]}
              id={"routine-set-form-#{set.id}"}
              phx-submit="update_set"
              class="flex flex-1 flex-wrap items-end gap-2"
            >
              <input type="hidden" name="set[id]" value={set.id} />
              <.input
                field={@set_forms[set.id][:reps_min]}
                type="number"
                label="Min reps"
                class="input w-20"
                min="1"
              />
              <.input
                field={@set_forms[set.id][:reps_max]}
                type="number"
                label="Max reps"
                class="input w-20"
                min="1"
              />
              <.input
                field={@set_forms[set.id][:rest_seconds]}
                type="number"
                label="Rest (s)"
                class="input w-24"
                min="0"
              />
              <.button type="submit" class="btn btn-primary btn-sm">Save</.button>
            </.form>

            <div class="flex flex-col">
              <button
                type="button"
                class="btn btn-ghost btn-xs btn-square"
                phx-click="move_up"
                phx-value-id={set.id}
                disabled={index == 0}
                aria-label="Move set up"
              >
                <.icon name="hero-chevron-up" class="size-4" />
              </button>
              <button
                type="button"
                class="btn btn-ghost btn-xs btn-square"
                phx-click="move_down"
                phx-value-id={set.id}
                disabled={index == length(@exercise.routine_sets) - 1}
                aria-label="Move set down"
              >
                <.icon name="hero-chevron-down" class="size-4" />
              </button>
            </div>

            <.button
              type="button"
              class="btn btn-error btn-soft btn-sm btn-square"
              phx-click="delete_set"
              phx-value-id={set.id}
              aria-label="Delete set"
            >
              <.icon name="hero-trash" class="size-4" />
            </.button>
          <% else %>
            <span class="flex-1">
              {set.reps_min}
              <%= if set.reps_max && set.reps_max > set.reps_min do %>
                –{set.reps_max}
              <% end %>
              reps
              <%= if set.rest_seconds && set.rest_seconds > 0 do %>
                · {set.rest_seconds}s rest
              <% end %>
            </span>
          <% end %>
        </li>

        <p :if={Enum.empty?(@exercise.routine_sets)} class="text-gray-500">
          No planned sets yet.
        </p>
      </ul>

      <%= if @is_owner do %>
        <h2 class="font-bold text-lg mt-4">Add a Set</h2>
        <.form
          for={@set_form}
          id="new_set_form"
          phx-submit="add_set"
          phx-change="validate_set"
          class="flex flex-wrap items-end gap-2"
        >
          <.input
            field={@set_form[:reps_min]}
            type="number"
            label="Min reps"
            class="input w-24"
            min="1"
          />
          <.input
            field={@set_form[:reps_max]}
            type="number"
            label="Max reps"
            class="input w-24"
            min="1"
          />
          <.input
            field={@set_form[:rest_seconds]}
            type="number"
            label="Rest (s)"
            class="input w-28"
            min="0"
          />
          <.button type="submit" class="btn btn-primary">Add Set</.button>
        </.form>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        %{"plan_id" => plan_id, "routine_id" => routine_id, "exercise_id" => exercise_id},
        _session,
        socket
      ) do
    plan_id = String.to_integer(plan_id)
    routine_id = String.to_integer(routine_id)
    exercise_id = String.to_integer(exercise_id)
    user_id = socket.assigns.current_scope.user.id

    is_owner = RoutineExercises.is_routine_exercise_from_user(exercise_id, user_id)

    case RoutineExercises.get_routine_exercise_with_sets(exercise_id) do
      {:ok, exercise} ->
        {:ok,
         socket
         |> assign(plan_id: plan_id, routine_id: routine_id, is_owner: is_owner)
         |> assign_exercise(exercise)
         |> assign_set_form()}

      {:error, _reason} ->
        {:error, :not_found}
    end
  end

  @impl true
  def handle_event("validate_set", %{"set" => params}, socket) do
    changeset =
      params
      |> RoutineSets.change_routine_set_map()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, set_form: to_form(changeset, as: "set", id: "new-set"))}
  end

  def handle_event("add_set", %{"set" => params}, socket) do
    params = Map.put(params, "routine_exercise_id", socket.assigns.exercise.id)

    case RoutineSets.add_set(params) do
      {:ok, _set} ->
        {:noreply, socket |> reload_exercise() |> assign_set_form()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, set_form: to_form(changeset, as: "set", id: "new-set"))}
    end
  end

  def handle_event("update_set", %{"set" => %{"id" => id} = params}, socket) do
    with true <- socket.assigns.is_owner,
         {:ok, set} <- RoutineSets.get_routine_set(String.to_integer(id)),
         {:ok, _} <- RoutineSets.update_set(set, params) do
      {:noreply, socket |> put_flash(:info, "Set updated.") |> reload_exercise()}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, "Couldn't update set: #{error_summary(changeset)}")}

      _ ->
        {:noreply, put_flash(socket, :error, "Couldn't update set.")}
    end
  end

  def handle_event("delete_set", %{"id" => id}, socket),
    do: with_owned_set(socket, id, &RoutineSets.soft_delete_set/1)

  def handle_event("move_up", %{"id" => id}, socket),
    do: with_owned_set(socket, id, &RoutineSets.move_set(&1, :up))

  def handle_event("move_down", %{"id" => id}, socket),
    do: with_owned_set(socket, id, &RoutineSets.move_set(&1, :down))

  def handle_event("reposition", %{"ids" => ids}, socket) do
    if socket.assigns.is_owner do
      ordered_ids = Enum.map(ids, &String.to_integer/1)
      RoutineSets.reposition(socket.assigns.exercise.id, ordered_ids)
      {:noreply, reload_exercise(socket)}
    else
      {:noreply, socket}
    end
  end

  defp with_owned_set(socket, id, fun) do
    if socket.assigns.is_owner do
      case RoutineSets.get_routine_set(String.to_integer(id)) do
        {:ok, set} -> fun.(set)
        _ -> :noop
      end

      {:noreply, reload_exercise(socket)}
    else
      {:noreply, socket}
    end
  end

  defp reload_exercise(socket) do
    {:ok, exercise} = RoutineExercises.get_routine_exercise_with_sets(socket.assigns.exercise.id)
    assign_exercise(socket, exercise)
  end

  # Pre-builds the per-set edit forms so the template can render prefilled,
  # error-aware inputs without constructing forms inline.
  defp assign_exercise(socket, exercise) do
    set_forms =
      Map.new(exercise.routine_sets, fn set ->
        {set.id, to_form(RoutineSets.change_routine_set(set), as: "set", id: "set-#{set.id}")}
      end)

    assign(socket, exercise: exercise, set_forms: set_forms)
  end

  defp assign_set_form(socket) do
    assign(socket,
      set_form: to_form(RoutineSets.change_routine_set_map(%{}), as: "set", id: "new-set")
    )
  end

  defp error_summary(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
    |> Enum.map_join("; ", fn {field, msgs} -> "#{field} #{Enum.join(msgs, ", ")}" end)
  end
end
