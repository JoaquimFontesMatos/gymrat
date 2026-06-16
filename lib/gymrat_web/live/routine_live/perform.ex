defmodule GymratWeb.RoutineLive.Perform do
  use GymratWeb, :live_view

  alias Gymrat.Training.Routines
  alias Gymrat.Training.RoutineSetLogs
  import GymratWeb.MyComponents

  defp exercise_label(exercise) do
    (exercise.exercise_id || exercise.custom_name || "Unknown Exercise")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp target_label(%{reps_min: reps_min, reps_max: reps_max})
       when is_integer(reps_max) and reps_max > reps_min,
       do: "target #{reps_min}–#{reps_max}"

  defp target_label(%{reps_min: reps_min}), do: "target #{reps_min}"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}/routines/#{@routine.id}"}
        title={"Log: #{@routine.name}"}
      />
      <p class="text-gray-500 text-sm">Record what you actually did today.</p>

      <div :for={exercise <- @routine.routine_exercises} class="mt-4">
        <div class="flex items-center gap-2">
          <.workout_icon name={exercise_icon(exercise)} class="w-8 h-11 text-primary shrink-0" />
          <h2 class="font-bold">{exercise_label(exercise)}</h2>
        </div>

        <p :if={Enum.empty?(exercise.routine_sets)} class="text-gray-500 text-sm pl-10">
          No planned sets.
        </p>

        <ul class="flex flex-col gap-2 mt-1">
          <li
            :for={{set, index} <- Enum.with_index(exercise.routine_sets, 1)}
            id={"perform-set-#{set.id}"}
            class="flex items-center gap-2 rounded-lg border border-base-300 p-2"
          >
            <span class="font-semibold w-14 shrink-0">
              Set {index}
            </span>
            <span class="text-gray-500 text-xs w-24 shrink-0">{target_label(set)}</span>

            <.form
              for={@log_forms[set.id]}
              id={"perform-set-form-#{set.id}"}
              phx-submit="log_set"
              class="flex flex-1 flex-wrap items-end gap-2"
            >
              <input type="hidden" name="log[set_id]" value={set.id} />
              <.input
                field={@log_forms[set.id][:reps]}
                type="number"
                label="Reps"
                class="input w-20"
                min="1"
              />
              <.input
                field={@log_forms[set.id][:weight]}
                type="number"
                label="Weight"
                class="input w-24"
                step="any"
                min="0"
              />
              <.button type="submit" class="btn btn-primary btn-sm">
                <%= if Map.has_key?(@todays, set.id) do %>
                  Update
                <% else %>
                  Log
                <% end %>
              </.button>
              <span :if={Map.has_key?(@todays, set.id)} class="text-success text-xs">
                <.icon name="hero-check" class="size-4" /> Logged
              </span>
            </.form>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"plan_id" => plan_id, "routine_id" => routine_id}, _session, socket) do
    plan_id = String.to_integer(plan_id)
    routine_id = String.to_integer(routine_id)

    case Routines.get_routine(routine_id) do
      {:ok, routine} ->
        {:ok, socket |> assign(plan_id: plan_id) |> load(routine)}

      {:error, _reason} ->
        {:error, :not_found}
    end
  end

  @impl true
  def handle_event("log_set", %{"log" => %{"set_id" => set_id} = params}, socket) do
    set_id = String.to_integer(set_id)
    user_id = socket.assigns.current_scope.user.id

    cond do
      not MapSet.member?(socket.assigns.valid_set_ids, set_id) ->
        {:noreply, put_flash(socket, :error, "Unknown set.")}

      true ->
        attrs = %{
          "reps" => params["reps"],
          "weight" => params["weight"],
          "routine_set_id" => set_id,
          "user_id" => user_id
        }

        result =
          case Map.get(socket.assigns.todays, set_id) do
            nil -> RoutineSetLogs.log_set(attrs)
            existing -> RoutineSetLogs.update_log(existing, attrs)
          end

        case result do
          {:ok, _} ->
            {:ok, routine} = Routines.get_routine(socket.assigns.routine.id)
            {:noreply, socket |> put_flash(:info, "Logged!") |> load(routine)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Couldn't log that set. Check reps and weight.")}
        end
    end
  end

  defp load(socket, routine) do
    user_id = socket.assigns.current_scope.user.id

    set_ids =
      routine.routine_exercises
      |> Enum.flat_map(& &1.routine_sets)
      |> Enum.map(& &1.id)

    todays = RoutineSetLogs.todays_logs_by_set(set_ids, user_id)

    log_forms =
      routine.routine_exercises
      |> Enum.flat_map(& &1.routine_sets)
      |> Map.new(fn set ->
        log = Map.get(todays, set.id)
        reps = if log, do: log.reps, else: set.reps_min
        weight = if log, do: log.weight, else: nil
        {set.id, to_form(%{"reps" => reps, "weight" => weight}, as: "log", id: "log-#{set.id}")}
      end)

    assign(socket,
      routine: routine,
      todays: todays,
      valid_set_ids: MapSet.new(set_ids),
      log_forms: log_forms
    )
  end
end
