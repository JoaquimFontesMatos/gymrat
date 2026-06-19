defmodule GymratWeb.RoutineExerciseLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.RoutineExercises
  alias Gymrat.Training.RoutineSets
  alias Gymrat.Training.RoutineSetLogs
  import GymratWeb.MyComponents

  @colors [
    %{border: "rgba(59, 130, 246, 0.7)", background: "rgba(59, 130, 246, 0.2)"},
    %{border: "rgba(168, 85, 247, 0.7)", background: "rgba(168, 85, 247, 0.2)"},
    %{border: "rgba(239, 68, 68, 0.7)", background: "rgba(239, 68, 68, 0.2)"},
    %{border: "rgba(234, 179, 8, 0.7)", background: "rgba(234, 179, 8, 0.2)"},
    %{border: "rgba(34, 197, 94, 0.7)", background: "rgba(34, 197, 94, 0.2)"}
  ]

  defp exercise_label(exercise) do
    (exercise.exercise_id || exercise.custom_name || "Unknown Exercise")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp set_summary(%{duration_seconds: d} = set) when is_integer(d) do
    join_parts(["#{d}s hold", rest_label(set.rest_seconds)])
  end

  defp set_summary(set) do
    join_parts([reps_label(set.reps_min, set.reps_max), rest_label(set.rest_seconds)])
  end

  defp join_parts(parts), do: parts |> Enum.reject(&is_nil/1) |> Enum.join(" · ")

  defp reps_label(min, max) when is_integer(max) and max > min, do: "#{min}–#{max} reps"
  defp reps_label(min, _max), do: "#{min} reps"

  defp rest_label(rest) when is_integer(rest) and rest > 0, do: "#{rest}s rest"
  defp rest_label(_rest), do: nil

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
          class="flex flex-col gap-3 rounded-xl border border-base-300 bg-base-100 p-3"
        >
          <%= if @is_owner do %>
            <div class="flex items-center gap-2">
              <span
                data-drag-handle
                class="touch-none select-none cursor-grab text-gray-400 hover:text-gray-600 active:cursor-grabbing shrink-0"
                aria-hidden="true"
              >
                <.icon name="hero-bars-3" class="size-5" />
              </span>
              <span class="font-semibold">Set {index + 1}</span>

              <div class="ml-auto flex items-center gap-1">
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
                <.button
                  type="button"
                  class="btn btn-error btn-ghost btn-xs btn-square"
                  phx-click="delete_set"
                  phx-value-id={set.id}
                  aria-label="Delete set"
                >
                  <.icon name="hero-trash" class="size-4" />
                </.button>
              </div>
            </div>

            <.form
              for={@set_forms[set.id]}
              id={"routine-set-form-#{set.id}"}
              phx-submit="update_set"
              class="grid grid-cols-2 sm:grid-cols-4 gap-x-3 gap-y-1 items-end"
            >
              <input type="hidden" name="set[id]" value={set.id} />
              <.input
                field={@set_forms[set.id][:reps_min]}
                type="number"
                label="Min reps"
                class="input input-sm w-full"
                min="1"
              />
              <.input
                field={@set_forms[set.id][:reps_max]}
                type="number"
                label="Max reps"
                class="input input-sm w-full"
                min="1"
              />
              <.input
                field={@set_forms[set.id][:duration_seconds]}
                type="number"
                label="Hold (s)"
                class="input input-sm w-full"
                min="1"
              />
              <.input
                field={@set_forms[set.id][:rest_seconds]}
                type="number"
                label="Rest (s)"
                class="input input-sm w-full"
                min="0"
              />
              <.button
                type="submit"
                class="col-span-2 sm:col-span-4 mt-1 btn btn-primary btn-sm w-full"
              >
                Save set
              </.button>
            </.form>
          <% else %>
            <div class="flex items-center gap-2">
              <span class="font-semibold shrink-0">Set {index + 1}</span>
              <span class="flex-1 text-gray-500">{set_summary(set)}</span>
            </div>
          <% end %>
        </li>

        <p :if={Enum.empty?(@exercise.routine_sets)} class="text-gray-500">
          No planned sets yet.
        </p>
      </ul>

      <%= if @is_owner do %>
        <h2 class="font-bold text-lg mt-4">Add a Set</h2>
        <p class="text-gray-500 text-xs mb-2">
          Fill in reps for a normal set, or a hold for a timed one.
        </p>
        <.form
          for={@set_form}
          id="new_set_form"
          phx-submit="add_set"
          phx-change="validate_set"
          class="grid grid-cols-2 sm:grid-cols-4 gap-x-3 gap-y-1 items-end rounded-xl border border-base-300 bg-base-100 p-3"
        >
          <.input
            field={@set_form[:reps_min]}
            type="number"
            label="Min reps"
            class="input input-sm w-full"
            min="1"
          />
          <.input
            field={@set_form[:reps_max]}
            type="number"
            label="Max reps"
            class="input input-sm w-full"
            min="1"
          />
          <.input
            field={@set_form[:duration_seconds]}
            type="number"
            label="Hold (s)"
            class="input input-sm w-full"
            min="1"
          />
          <.input
            field={@set_form[:rest_seconds]}
            type="number"
            label="Rest (s)"
            class="input input-sm w-full"
            min="0"
          />
          <.button type="submit" class="col-span-2 sm:col-span-4 mt-1 btn btn-primary btn-sm w-full">
            Add Set
          </.button>
        </.form>
      <% end %>

      <section class="mt-6">
        <h2
          :if={@reps_chart_data || @weight_chart_data || @duration_chart_data}
          class="mb-2 font-medium text-sm text-base-content/60 uppercase tracking-wide"
        >
          Progress
        </h2>
        <div
          id="chart-loader"
          phx-hook="ChartLoader"
          class="flex md:flex-row flex-col flex-wrap justify-center items-center gap-4 w-full"
        >
          <div :if={@reps_chart_data}>
            <canvas
              id="repsProgressChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@reps_chart_data)}
              data-y-axis-title="Reps"
            ></canvas>
          </div>
          <div :if={@weight_chart_data}>
            <canvas
              id="weightProgressChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@weight_chart_data)}
              data-y-axis-title="Weight (kg)"
            ></canvas>
          </div>
          <div :if={@duration_chart_data}>
            <canvas
              id="durationProgressChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@duration_chart_data)}
              data-y-axis-title="Duration (s)"
            ></canvas>
          </div>
        </div>
      </section>
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
         |> assign(weight_chart_data: nil, reps_chart_data: nil, duration_chart_data: nil)
         |> assign_exercise(exercise)
         |> assign_set_form()
         |> push_event("load_chart_data", %{})}

      {:error, _reason} ->
        {:error, :not_found}
    end
  end

  @impl true
  def handle_event("load_chart_data", _params, socket) do
    user_id = socket.assigns.current_scope.user.id
    logs = RoutineSetLogs.logs_by_day(socket.assigns.exercise.id, user_id)

    {:noreply,
     assign(socket,
       weight_chart_data: build_chart(logs, :weight),
       reps_chart_data: build_chart(logs, :reps),
       duration_chart_data: build_chart(logs, :duration_seconds)
     )}
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

  # Builds a Chart.js line dataset for one metric from the logs: one line per
  # set position (ordered within each day), plotted across days. Returns nil
  # when no log carries that metric, so the template can hide the canvas.
  defp build_chart(logs, key) do
    logs = Enum.filter(logs, &(Map.get(&1, key) != nil))

    if logs == [] do
      nil
    else
      by_day = Enum.group_by(logs, & &1.day)

      days =
        by_day |> Map.keys() |> Enum.sort(fn a, b -> Date.compare(a, b) != :gt end)

      datasets =
        by_day
        |> Enum.flat_map(fn {day, items} ->
          Enum.with_index(items, fn item, idx ->
            %{day: day, index: idx, value: Map.get(item, key)}
          end)
        end)
        |> Enum.group_by(& &1.index)
        |> Enum.sort_by(fn {index, _} -> index end)
        |> Enum.map(fn {index, points} ->
          values = Map.new(points, fn %{day: d, value: v} -> {d, v} end)
          color = Enum.at(@colors, index, List.last(@colors))

          %{
            label: "Set #{index + 1}",
            data: Enum.map(days, &Map.get(values, &1)),
            borderColor: color.border,
            backgroundColor: color.background,
            fill: false,
            tension: 0.3
          }
        end)

      %{labels: Enum.map(days, &Calendar.strftime(&1, "%d-%m-%y")), datasets: datasets}
    end
  end
end
