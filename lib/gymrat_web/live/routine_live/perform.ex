defmodule GymratWeb.RoutineLive.Perform do
  use GymratWeb, :live_view

  alias Gymrat.Training.Routines
  alias Gymrat.Training.RoutineSetLogs
  alias Gymrat.Routines.{RoutineSet, RoutineSetLog}
  alias Gymrat.ExerciseCache
  import GymratWeb.MyComponents

  defp exercise_label(exercise) do
    (exercise.exercise_id || exercise.custom_name || "Unknown Exercise")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp target_label(%{duration_seconds: duration}) when is_integer(duration),
    do: "hold #{duration}s"

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

      <%= case @phase do %>
        <% :empty -> %>
          <p class="text-gray-500 mt-4">This routine has no planned sets yet.</p>
          <.link
            navigate={~p"/plans/#{@plan_id}/routines/#{@routine.id}"}
            class="btn btn-primary mt-4"
          >
            Back to routine
          </.link>
        <% :done -> %>
          <div class="flex flex-col items-center gap-4 mt-10 text-center">
            <p class="text-5xl">💪</p>
            <h2 class="font-bold text-2xl">Session complete</h2>
            <p class="text-gray-500">
              {@logged_today} of {@total} {if @total == 1, do: "set", else: "sets"} logged today
            </p>
            <.link navigate={~p"/plans/#{@plan_id}/routines/#{@routine.id}"} class="btn btn-primary">
              Back to routine
            </.link>
            <.button type="button" phx-click="restart" class="btn btn-ghost">
              Restart session
            </.button>
          </div>
        <% :set -> %>
          <div class="mx-auto max-w-sm">
            <.session_progress index={@index} total={@total} />

            <.exercise_image
              exercise={@current.exercise}
              class="w-full h-48 object-cover rounded-xl mt-4 bg-base-200"
            />

            <div class="flex items-center gap-3 mt-3">
              <.workout_icon
                name={exercise_icon(@current.exercise)}
                class="w-8 h-11 text-primary shrink-0"
              />
              <div class="flex-1">
                <h2 class="font-bold">{exercise_label(@current.exercise)}</h2>
                <p class="text-gray-500 text-sm">
                  Set {@current.set_number} of {@current.set_count} · {target_label(@current.set)}
                </p>
              </div>
              <button
                type="button"
                phx-click="show_info"
                class="btn btn-ghost btn-sm btn-circle shrink-0"
                aria-label="Exercise info"
              >
                <.icon name="hero-information-circle" class="size-6 text-primary" />
              </button>
            </div>

            <div
              :if={RoutineSet.time_based?(@current.set)}
              id={"work-timer-#{@index}"}
              phx-hook="RestTimer"
              phx-update="ignore"
              data-timer-key={"routine-#{@routine.id}-work-#{@index}"}
              class="flex flex-col items-center gap-2 bg-base-100 shadow-sm p-4 border border-base-300 rounded-2xl mt-4 transition-shadow"
            >
              <span class="flex items-center gap-2 font-medium text-sm text-base-content/60 uppercase tracking-wide">
                <.icon name="hero-clock" class="w-5 h-5" /> Hold
              </span>
              <span data-role="display" class="font-mono font-bold tabular-nums text-5xl">
                0:00
              </span>
              <button
                type="button"
                data-rest={@current.set.duration_seconds}
                class="btn btn-sm btn-primary"
              >
                Start {@current.set.duration_seconds}s
              </button>
            </div>

            <.form
              for={@form}
              id="guided-set-form"
              phx-submit="log_set"
              class="flex flex-col gap-3 mt-4"
            >
              <.input
                :if={RoutineSet.time_based?(@current.set)}
                field={@form[:duration_seconds]}
                type="number"
                label="Seconds held"
                min="1"
              />
              <.input
                :if={not RoutineSet.time_based?(@current.set)}
                field={@form[:reps]}
                type="number"
                label="Reps"
                min="1"
              />
              <.input
                field={@form[:weight]}
                type="number"
                label={
                  if RoutineSet.time_based?(@current.set),
                    do: "Weight (kg, optional)",
                    else: "Weight (kg)"
                }
                step="any"
                min="0"
              />
              <.button type="submit" class="btn btn-primary w-full">Log set →</.button>
            </.form>

            <.button type="button" phx-click="skip" class="btn btn-ghost w-full mt-2">
              Skip
            </.button>
          </div>
        <% :rest -> %>
          <div class="mx-auto max-w-sm flex flex-col items-center gap-5 mt-6">
            <.session_progress index={@index} total={@total} />

            <div
              id="rest-timer"
              phx-hook="RestTimer"
              phx-update="ignore"
              data-timer-key={"routine-#{@routine.id}-rest-#{@index}"}
              data-autostart-seconds={@current.set.rest_seconds}
              data-on-complete="next"
              class="flex flex-col items-center gap-2 bg-base-100 shadow-sm p-6 border border-base-300 rounded-2xl w-full transition-shadow"
            >
              <span class="flex items-center gap-2 font-medium text-sm text-base-content/60 uppercase tracking-wide">
                <.icon name="hero-clock" class="w-5 h-5" /> Rest
              </span>
              <span data-role="display" class="font-mono font-bold tabular-nums text-5xl">
                0:00
              </span>
              <button type="button" data-rest-add="15" class="btn btn-sm btn-soft btn-primary">
                +15s
              </button>
              <label class="flex items-center gap-2 text-sm text-base-content/70 cursor-pointer mt-1">
                <input type="checkbox" data-role="autoskip" class="toggle toggle-primary toggle-sm" />
                Auto-skip when done
              </label>
            </div>

            <p class="text-gray-500 text-sm">Up next: set {@index + 2} of {@total}</p>

            <.button type="button" phx-click="next" class="btn btn-primary w-full">
              Skip →
            </.button>
          </div>
      <% end %>

      <.modal :if={@show_info and @current} id="exercise-info-modal" on_cancel={JS.push("hide_info")}>
        <.exercise_info_body
          exercise={@current.exercise}
          info={@infos[@current.exercise.exercise_id]}
        />
        <div class="modal-action">
          <.button phx-click="hide_info">Close</.button>
        </div>
      </.modal>
    </Layouts.app>
    """
  end

  attr :index, :integer, required: true
  attr :total, :integer, required: true

  defp session_progress(assigns) do
    ~H"""
    <div>
      <p class="text-gray-500 text-xs mb-1">Step {@index + 1} of {@total}</p>
      <progress class="progress progress-primary w-full" value={@index + 1} max={@total}></progress>
    </div>
    """
  end

  attr :exercise, :any, required: true
  attr :class, :string, default: ""

  # Provider exercises derive their image straight from `exercise_id` (the
  # free-exercise-db id), with png/webp fallbacks via onerror; custom exercises
  # use their stored URL, falling back to the bundled placeholder.
  defp exercise_image(%{exercise: %{exercise_id: id}} = assigns) when is_binary(id) do
    base = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises"

    assigns =
      assign(assigns,
        jpg: "#{base}/#{id}/0.jpg",
        png: "#{base}/#{id}/0.png",
        webp: "#{base}/#{id}/0.webp"
      )

    ~H"""
    <img
      loading="lazy"
      src={@jpg}
      data-png={@png}
      data-webp={@webp}
      alt={exercise_label(@exercise)}
      class={@class}
      onerror="this.onerror=null; if(this.src.endsWith('.jpg')) {this.src=this.dataset.png;} else if(this.src.endsWith('.png')) {this.src=this.dataset.webp;} else {this.src='/images/default_exercise.jpg';}"
    />
    """
  end

  defp exercise_image(assigns) do
    ~H"""
    <img
      :if={@exercise.custom_image_url}
      loading="lazy"
      src={@exercise.custom_image_url}
      alt={exercise_label(@exercise)}
      class={@class}
    />
    """
  end

  attr :exercise, :any, required: true
  attr :info, :any, default: nil

  # Modal body. Custom exercises render their stored description; provider
  # exercises render the cached reference data (`@info`), or a loading/empty
  # state while the async fetch is in flight or unavailable.
  defp exercise_info_body(%{exercise: %{exercise_id: id}} = assigns) when is_binary(id) do
    ~H"""
    <div class="flex flex-col gap-3">
      <h2 class="font-bold text-lg">{exercise_label(@exercise)}</h2>
      <.exercise_image exercise={@exercise} class="w-full h-48 object-cover rounded-xl bg-base-200" />

      <%= cond do %>
        <% is_map(@info) -> %>
          <p :if={@info["primaryMuscles"]}>
            <strong>Primary:</strong> {Enum.join(List.wrap(@info["primaryMuscles"]), ", ")}
          </p>
          <p :if={@info["secondaryMuscles"] not in [nil, []]}>
            <strong>Secondary:</strong> {Enum.join(List.wrap(@info["secondaryMuscles"]), ", ")}
          </p>
          <p :if={@info["equipment"]}><strong>Equipment:</strong> {@info["equipment"]}</p>
          <p :if={@info["level"]}><strong>Level:</strong> {@info["level"]}</p>
          <ol :if={@info["instructions"] not in [nil, []]} class="ml-4">
            <li :for={step <- List.wrap(@info["instructions"])} class="list-decimal">{step}</li>
          </ol>
        <% @info == :error -> %>
          <p class="text-gray-500">Couldn't load exercise details right now.</p>
        <% true -> %>
          <p class="text-gray-500">Loading details…</p>
      <% end %>
    </div>
    """
  end

  defp exercise_info_body(assigns) do
    ~H"""
    <div class="flex flex-col gap-3">
      <h2 class="font-bold text-lg">{exercise_label(@exercise)}</h2>
      <.exercise_image exercise={@exercise} class="w-full h-48 object-cover rounded-xl bg-base-200" />
      <p>{@exercise.custom_description || "No description provided."}</p>
    </div>
    """
  end

  @impl true
  def mount(%{"plan_id" => plan_id, "routine_id" => routine_id}, _session, socket) do
    plan_id = String.to_integer(plan_id)
    routine_id = String.to_integer(routine_id)

    case Routines.get_routine(routine_id) do
      {:ok, routine} ->
        socket =
          socket
          |> assign(plan_id: plan_id, routine: routine, show_info: false, infos: %{})
          |> load_session()

        {:ok, socket}

      {:error, _reason} ->
        {:error, :not_found}
    end
  end

  # Step/phase live in the URL so a reload restores the exact position. Absent
  # params (fresh entry) resume at the first set with no log today.
  @impl true
  def handle_params(params, _uri, socket) do
    steps = socket.assigns.steps
    todays = socket.assigns.todays

    socket =
      cond do
        steps == [] ->
          assign(socket, phase: :empty, index: 0, current: nil, form: nil)

        params["phase"] == "done" ->
          done(socket)

        is_nil(params["step"]) ->
          case first_unlogged(steps, todays) do
            nil -> done(socket)
            index -> goto(socket, index, :set)
          end

        true ->
          phase = if params["phase"] == "rest", do: :rest, else: :set
          goto(socket, clamp_index(params["step"], length(steps)), phase)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("log_set", %{"log" => params}, socket) do
    step = socket.assigns.current
    user_id = socket.assigns.current_scope.user.id
    set_id = step.set.id

    attrs = %{
      "reps" => params["reps"],
      "duration_seconds" => params["duration_seconds"],
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
      {:ok, log} ->
        socket = assign(socket, todays: Map.put(socket.assigns.todays, set_id, log))
        {index, phase} = advance_coords(socket, true)
        {:noreply, patch_to(socket, index, phase)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "log", id: "guided-log"))}
    end
  end

  def handle_event("skip", _params, socket) do
    {index, phase} = advance_coords(socket, false)
    {:noreply, patch_to(socket, index, phase)}
  end

  def handle_event("next", _params, socket),
    do: {:noreply, patch_to(socket, socket.assigns.index + 1, :set)}

  def handle_event("restart", _params, socket), do: {:noreply, patch_to(socket, 0, :set)}

  def handle_event("hide_info", _params, socket), do: {:noreply, assign(socket, show_info: false)}

  def handle_event("show_info", _params, socket) do
    socket = assign(socket, show_info: true)
    id = socket.assigns.current.exercise.exercise_id

    # Fetch provider reference data lazily (cached); custom exercises need none.
    if is_binary(id) and not Map.has_key?(socket.assigns.infos, id) do
      {:noreply, start_async(socket, :fetch_info, fn -> {id, ExerciseCache.get_exercise(id)} end)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_async(:fetch_info, {:ok, {id, {:ok, exercise}}}, socket) do
    {:noreply, assign(socket, infos: Map.put(socket.assigns.infos, id, exercise))}
  end

  def handle_async(:fetch_info, {:ok, {id, {:error, _reason}}}, socket) do
    {:noreply, assign(socket, infos: Map.put(socket.assigns.infos, id, :error))}
  end

  def handle_async(:fetch_info, {:exit, _reason}, socket) do
    {:noreply, socket}
  end

  # Assigns the position-independent session data; phase/index are decided by
  # handle_params (which always runs right after mount).
  defp load_session(socket) do
    routine = socket.assigns.routine
    user_id = socket.assigns.current_scope.user.id

    steps =
      for exercise <- routine.routine_exercises,
          {set, i} <- Enum.with_index(exercise.routine_sets, 1) do
        %{exercise: exercise, set: set, set_number: i, set_count: length(exercise.routine_sets)}
      end

    todays = RoutineSetLogs.todays_logs_by_set(Enum.map(steps, & &1.set.id), user_id)

    assign(socket, steps: steps, total: length(steps), todays: todays, current: nil, form: nil)
  end

  # Forward-only progression. After logging (`rest? = true`) a non-final set with
  # a planned rest, go to the rest screen; otherwise the next set or completion.
  defp advance_coords(socket, rest?) do
    index = socket.assigns.index
    rest_seconds = socket.assigns.current.set.rest_seconds

    cond do
      index >= socket.assigns.total - 1 -> {index, :done}
      rest? and is_integer(rest_seconds) and rest_seconds > 0 -> {index, :rest}
      true -> {index + 1, :set}
    end
  end

  defp patch_to(socket, index, phase) do
    push_patch(socket,
      to:
        ~p"/plans/#{socket.assigns.plan_id}/routines/#{socket.assigns.routine.id}/perform?#{[step: index, phase: phase]}"
    )
  end

  defp goto(socket, index, phase) do
    socket
    |> assign(index: index, phase: phase, current: Enum.at(socket.assigns.steps, index))
    |> assign_form()
  end

  defp done(socket) do
    assign(socket,
      phase: :done,
      current: nil,
      form: nil,
      logged_today: map_size(socket.assigns.todays)
    )
  end

  defp first_unlogged(steps, todays),
    do: Enum.find_index(steps, &(not Map.has_key?(todays, &1.set.id)))

  defp clamp_index(step_str, count) do
    case Integer.parse(to_string(step_str)) do
      {i, _} when i >= 0 and i < count -> i
      _ -> 0
    end
  end

  # Prefills the current set's form from today's log if it exists, else from the
  # planned target (reps or duration). The changeset has no `:action`, so the
  # missing routine_set_id/user_id don't surface as errors until a real submit.
  defp assign_form(socket) do
    set = socket.assigns.current.set
    log = Map.get(socket.assigns.todays, set.id)

    attrs =
      cond do
        RoutineSet.time_based?(set) ->
          %{
            "duration_seconds" => (log && log.duration_seconds) || set.duration_seconds,
            "weight" => log && log.weight
          }

        is_nil(log) ->
          %{"reps" => set.reps_min}

        true ->
          %{"reps" => log.reps, "weight" => log.weight}
      end

    form =
      to_form(RoutineSetLogs.change_log(%RoutineSetLog{}, attrs), as: "log", id: "guided-log")

    assign(socket, form: form)
  end
end
