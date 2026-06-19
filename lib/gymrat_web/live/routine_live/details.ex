defmodule GymratWeb.RoutineLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.Routines
  alias Gymrat.Training.RoutineExercises
  alias Gymrat.Training.RoutineSetLogs
  import GymratWeb.MyComponents

  @chart_colors %{
    volume: %{border: "rgba(59, 130, 246, 0.7)", background: "rgba(59, 130, 246, 0.2)"},
    reps: %{border: "rgba(168, 85, 247, 0.7)", background: "rgba(168, 85, 247, 0.2)"},
    duration: %{border: "rgba(34, 197, 94, 0.7)", background: "rgba(34, 197, 94, 0.2)"}
  }

  @doc false
  def format_set(%{duration_seconds: duration, rest_seconds: rest}) when is_integer(duration) do
    ["#{duration}s hold", rest_label(rest)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  def format_set(%{reps_min: reps_min, reps_max: reps_max, rest_seconds: rest}) do
    [reps_label(reps_min, reps_max), rest_label(rest)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp reps_label(reps_min, reps_max)
       when is_integer(reps_max) and reps_max > reps_min,
       do: "#{reps_min}–#{reps_max} reps"

  defp reps_label(reps_min, _reps_max), do: "#{reps_min} reps"

  defp rest_label(nil), do: nil
  defp rest_label(0), do: nil
  defp rest_label(seconds) when seconds < 60, do: "#{seconds}s rest"

  defp rest_label(seconds) do
    minutes = div(seconds, 60)
    rem_seconds = rem(seconds, 60)
    if rem_seconds == 0, do: "#{minutes}m rest", else: "#{minutes}m #{rem_seconds}s rest"
  end

  defp exercise_label(exercise) do
    (exercise.exercise_id || exercise.custom_name || "Unknown Exercise")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp get_localized_weekdays([]), do: "No weekday"

  defp get_localized_weekdays(weekdays) when is_list(weekdays) do
    weekdays
    |> Enum.sort_by(& &1.weekday)
    |> Enum.map_join(", ", &weekday_to_string(&1.weekday))
  end

  defp weekday_to_string(weekday) do
    case weekday do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
      _ -> "No weekday"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex justify-between items-center gap-2">
        <.header_with_back_navigate navigate={~p"/plans/#{@plan_id}"} title={@routine.name} />

        <div class="flex flex-wrap justify-end gap-2">
          <.button
            :if={@is_routine_owner}
            phx-click="edit_routine"
            class="btn btn-primary btn-soft btn-square"
          >
            <.icon name="hero-pencil-square" class="size-[1.2em]" />
          </.button>

          <.button
            :if={@is_routine_owner}
            class="btn btn-error btn-soft btn-square"
            phx-click="show_modal"
          >
            <.icon name="hero-trash" class="size-[1.2em]" />
          </.button>

          <.modal :if={@show_modal} id="confirm-modal" on_cancel={JS.push("hide_modal")}>
            <h2>Are you sure you want to delete this routine?</h2>
            <p>This action cannot be undone.</p>
            <div class="modal-action">
              <.button phx-click="hide_modal">Cancel</.button>
              <.button class="btn btn-error" phx-click="delete_routine">Confirm</.button>
            </div>
          </.modal>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <.workout_icon name={resolve_icon(@routine)} class="w-14 h-20 text-primary" />

        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          class="fill-primary/50 size-[1.2em]"
        >
          <path
            fill-rule="evenodd"
            d="M6.75 2.25A.75.75 0 0 1 7.5 3v1.5h9V3A.75.75 0 0 1 18 3v1.5h.75a3 3 0 0 1 3 3v11.25a3 3 0 0 1-3 3H5.25a3 3 0 0 1-3-3V7.5a3 3 0 0 1 3-3H6V3a.75.75 0 0 1 .75-.75Zm13.5 9a1.5 1.5 0 0 0-1.5-1.5H5.25a1.5 1.5 0 0 0-1.5 1.5v7.5a1.5 1.5 0 0 0 1.5 1.5h13.5a1.5 1.5 0 0 0 1.5-1.5v-7.5Z"
            clip-rule="evenodd"
          />
        </svg>

        <span class="text-gray-500">{get_localized_weekdays(@weekdays)}</span>
      </div>

      <div class="flex justify-between items-center">
        <h2 class="font-bold text-lg">Exercises</h2>
        <.link
          :if={!Enum.empty?(@routine.routine_exercises)}
          navigate={~p"/plans/#{@plan_id}/routines/#{@routine.id}/perform"}
          class="btn btn-secondary btn-sm"
        >
          Log a session
        </.link>
      </div>

      <ul id="routine-exercises" phx-hook="Sortable" class="flex flex-col gap-2">
        <li
          :for={{exercise, index} <- Enum.with_index(@routine.routine_exercises)}
          id={"routine-exercise-#{exercise.id}"}
          data-sortable-item
          data-id={exercise.id}
          class="flex items-center gap-2 rounded-lg border border-base-300 p-2"
        >
          <div :if={@is_routine_owner} class="flex flex-col items-center">
            <span
              data-drag-handle
              class="touch-none select-none cursor-grab text-gray-400 hover:text-gray-600 active:cursor-grabbing"
              aria-hidden="true"
            >
              <.icon name="hero-bars-3" class="size-4" />
            </span>
            <button
              type="button"
              class="btn btn-ghost btn-xs btn-square"
              phx-click="move_up"
              phx-value-id={exercise.id}
              disabled={index == 0}
              aria-label="Move up"
            >
              <.icon name="hero-chevron-up" class="size-4" />
            </button>
            <button
              type="button"
              class="btn btn-ghost btn-xs btn-square"
              phx-click="move_down"
              phx-value-id={exercise.id}
              disabled={index == length(@routine.routine_exercises) - 1}
              aria-label="Move down"
            >
              <.icon name="hero-chevron-down" class="size-4" />
            </button>
          </div>

          <.link
            navigate={~p"/plans/#{@plan_id}/routines/#{@routine.id}/exercises/#{exercise.id}"}
            class="flex flex-1 items-center gap-2 hover:text-secondary"
          >
            <.workout_icon name={exercise_icon(exercise)} class="w-9 h-12 text-primary shrink-0" />
            <div class="flex flex-col">
              <span>{exercise_label(exercise)}</span>
              <span :if={Enum.empty?(exercise.routine_sets)} class="text-gray-500 text-xs">
                No planned sets yet
              </span>
              <span
                :for={{set, set_index} <- Enum.with_index(exercise.routine_sets, 1)}
                class="text-gray-500 text-xs"
              >
                Set {set_index}: {format_set(set)}
              </span>
            </div>
          </.link>
        </li>

        <%= if Enum.empty?(@routine.routine_exercises) do %>
          <p>
            No exercises added yet.
            <a
              :if={@is_routine_owner}
              class="hover:text-secondary underline"
              href={~p"/plans/#{@plan_id}/routines/#{@routine.id}/exercises/new"}
            >
              Add one!
            </a>
          </p>
        <% else %>
          <.button :if={@is_routine_owner} phx-click="add_exercise" class="w-full btn btn-primary">
            Add an Exercise
          </.button>
        <% end %>
      </ul>

      <section class="mt-8">
        <h2
          :if={@volume_chart_data || @reps_chart_data || @duration_chart_data}
          class="mb-2 font-bold text-lg"
        >
          Progress
        </h2>
        <div
          id="routine-chart-loader"
          phx-hook="ChartLoader"
          class="flex md:flex-row flex-col flex-wrap justify-center items-center gap-4 w-full"
        >
          <div :if={@volume_chart_data}>
            <canvas
              id="routineVolumeChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@volume_chart_data)}
              data-y-axis-title="Volume (kg)"
            ></canvas>
          </div>
          <div :if={@reps_chart_data}>
            <canvas
              id="routineRepsChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@reps_chart_data)}
              data-y-axis-title="Reps"
            ></canvas>
          </div>
          <div :if={@duration_chart_data}>
            <canvas
              id="routineDurationChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@duration_chart_data)}
              data-y-axis-title="Session duration (min)"
            ></canvas>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"plan_id" => plan_id, "routine_id" => routine_id}, _session, socket) do
    plan_id = String.to_integer(plan_id)
    routine_id = String.to_integer(routine_id)
    user_id = socket.assigns.current_scope.user.id

    is_routine_owner = Routines.is_routine_from_user(routine_id, user_id)

    case Routines.get_routine(routine_id) do
      {:ok, routine} ->
        {:ok,
         socket
         |> assign(
           plan_id: plan_id,
           routine: routine,
           weekdays: Routines.get_routine_weekdays(routine_id),
           show_modal: false,
           is_routine_owner: is_routine_owner,
           volume_chart_data: nil,
           reps_chart_data: nil,
           duration_chart_data: nil
         )
         |> push_event("load_chart_data", %{})}

      {:error, _reason} ->
        {:error, :not_found}
    end
  end

  @impl true
  def handle_event("load_chart_data", _params, socket) do
    user_id = socket.assigns.current_scope.user.id
    rows = RoutineSetLogs.routine_totals_by_day(socket.assigns.routine.id, user_id)

    {:noreply,
     assign(socket,
       volume_chart_data: total_chart(rows, :volume, "Volume (kg)", @chart_colors.volume),
       reps_chart_data: total_chart(rows, :reps, "Reps", @chart_colors.reps),
       duration_chart_data:
         total_chart(rows, :duration, "Session duration (min)", @chart_colors.duration)
     )}
  end

  @impl true
  def handle_event("add_exercise", _payload, socket) do
    {:noreply,
     push_navigate(socket,
       to:
         ~p"/plans/#{socket.assigns.plan_id}/routines/#{socket.assigns.routine.id}/exercises/new"
     )}
  end

  def handle_event("edit_routine", _payload, socket) do
    {:noreply,
     push_navigate(socket,
       to: ~p"/plans/#{socket.assigns.plan_id}/routines/#{socket.assigns.routine.id}/edit"
     )}
  end

  def handle_event("show_modal", _params, socket),
    do: {:noreply, assign(socket, :show_modal, true)}

  def handle_event("hide_modal", _params, socket),
    do: {:noreply, assign(socket, :show_modal, false)}

  def handle_event("move_up", %{"id" => id}, socket), do: move(socket, id, :up)
  def handle_event("move_down", %{"id" => id}, socket), do: move(socket, id, :down)

  def handle_event("reposition", %{"ids" => ids}, socket) do
    if socket.assigns.is_routine_owner do
      ordered_ids = Enum.map(ids, &String.to_integer/1)
      RoutineExercises.reposition(socket.assigns.routine.id, ordered_ids)
      {:ok, routine} = Routines.get_routine(socket.assigns.routine.id)
      {:noreply, assign(socket, :routine, routine)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_routine", _payload, socket) do
    case Routines.soft_delete_routine(socket.assigns.routine) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "The routine was deleted!")
         |> push_navigate(to: ~p"/plans/#{socket.assigns.plan_id}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete the routine!")}
    end
  end

  defp move(socket, id, direction) do
    if socket.assigns.is_routine_owner do
      exercise =
        Enum.find(socket.assigns.routine.routine_exercises, &(&1.id == String.to_integer(id)))

      if exercise do
        RoutineExercises.move_exercise(exercise, direction)
      end

      {:ok, routine} = Routines.get_routine(socket.assigns.routine.id)
      {:noreply, assign(socket, :routine, routine)}
    else
      {:noreply, socket}
    end
  end

  # Single-line Chart.js dataset of one daily total across the routine. Returns
  # nil when no day carries that metric so the template can hide the canvas.
  defp total_chart(rows, key, label, color) do
    points = Enum.reject(rows, &is_nil(Map.get(&1, key)))

    if points == [] do
      nil
    else
      %{
        labels: Enum.map(points, &Calendar.strftime(&1.day, "%d-%m-%y")),
        datasets: [
          %{
            label: label,
            data: Enum.map(points, &Map.get(&1, key)),
            borderColor: color.border,
            backgroundColor: color.background,
            fill: false,
            tension: 0.3
          }
        ]
      }
    end
  end
end
