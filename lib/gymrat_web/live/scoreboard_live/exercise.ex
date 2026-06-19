defmodule GymratWeb.ScoreboardLive.Exercise do
  use GymratWeb, :live_view

  alias Gymrat.Training.{Plans, Sets}
  alias Gymrat.ExerciseCache
  import GymratWeb.MyComponents

  @periods %{"weekly" => :weekly, "monthly" => :monthly, "all_time" => :all_time}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate navigate={~p"/scoreboard"} title={@title} />

      <form id="scope-form" phx-change="select_scope" class="mt-4 mb-4 space-y-2">
        <label :if={@plans != []} class="flex items-center gap-2">
          <.icon name="hero-user-group" class="h-5 w-5 shrink-0 text-base-content/60" />
          <select name="plan_id" class="select select-bordered w-full" aria-label="Leaderboard group">
            <option value="" selected={is_nil(@selected_plan_id)}>Everyone</option>
            <option :for={plan <- @plans} value={plan.id} selected={@selected_plan_id == plan.id}>
              {plan.name}
            </option>
          </select>
        </label>

        <label class="flex items-center gap-2">
          <.icon name="hero-bolt" class="h-5 w-5 shrink-0 text-base-content/60" />
          <select name="exercise" class="select select-bordered w-full" aria-label="Exercise">
            <option value="" selected={is_nil(@selected_exercise)}>Select an exercise…</option>
            <option
              :for={opt <- @exercise_options}
              value={opt.value}
              selected={@selected_exercise == opt.value}
            >
              {opt.label}
            </option>
          </select>
        </label>
      </form>

      <div role="tablist" class="tabs tabs-boxed mb-4">
        <.link
          :for={
            {label, period} <- [{"Weekly", :weekly}, {"Monthly", :monthly}, {"All-Time", :all_time}]
          }
          patch={
            ~p"/scoreboard/exercise?#{scope_params(@selected_plan_id, @selected_exercise, period)}"
          }
          role="tab"
          class={"tab " <> if(@period == period, do: "tab-active", else: "")}
        >
          {label}
        </.link>
      </div>

      <p :if={@exercise_options == []} class="text-base-content/60">
        No exercises have been logged yet.
      </p>

      <p :if={@exercise_options != [] and is_nil(@selected_exercise)} class="text-base-content/60">
        Pick an exercise above to see who lifts the heaviest.
      </p>

      <.scoreboard_table
        :if={@selected_exercise}
        value_header="Max weight"
        rows={Enum.map(@scores, &%{user: &1.user, value: "#{round(&1.score)} kg"})}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_payload, _session, socket) do
    plans = Plans.list_my_plans(socket.assigns.current_scope.user.id)
    # :unset (never a real plan id, not even nil/"Everyone") forces the first
    # handle_params to build the options regardless of the default scope.
    {:ok, assign(socket, plans: plans, options_plan_id: :unset)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    period = Map.get(@periods, params["period"], :weekly)
    selected_plan_id = parse_plan_id(params["plan_id"], socket.assigns.plans)
    socket = ensure_exercise_options(socket, selected_plan_id)
    exercise_options = socket.assigns.exercise_options
    selected = find_exercise(params["exercise"], exercise_options)

    scores =
      if selected do
        Sets.get_exercise_max_weight(
          selected.exercise_id,
          selected.custom_name,
          period,
          selected_plan_id
        )
      else
        []
      end

    {:noreply,
     socket
     |> assign(:period, period)
     |> assign(:selected_plan_id, selected_plan_id)
     |> assign(:selected_exercise, selected && selected.value)
     |> assign(:scores, scores)
     |> assign(:title, title(selected))}
  end

  @impl true
  def handle_event("select_scope", params, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/scoreboard/exercise?#{scope_params(params["plan_id"], params["exercise"], socket.assigns.period)}"
     )}
  end

  defp title(nil), do: "Exercise Scoreboard"
  defp title(%{label: label}), do: "#{label} — Max Weight"

  # The exercise list only depends on the plan scope, but resolving provider
  # names is comparatively expensive (a cache lookup, or an API call on a cold
  # cache). Rebuild it only when the plan scope actually changes so switching
  # period tabs is instant.
  defp ensure_exercise_options(socket, plan_id) do
    if socket.assigns[:options_plan_id] == plan_id do
      socket
    else
      assign(socket,
        exercise_options: build_exercise_options(plan_id),
        options_plan_id: plan_id
      )
    end
  end

  # Builds the picker options from the exercises that actually have logged sets,
  # resolving a display name for each (provider name via the cache, or the custom
  # name as-is). Names are resolved concurrently so a cold cache doesn't serialize
  # one flaky API round-trip after another.
  defp build_exercise_options(plan_id) do
    plan_id
    |> Sets.list_scored_exercises()
    |> Task.async_stream(&to_option/1,
      ordered: false,
      max_concurrency: 10,
      timeout: 15_000,
      on_timeout: :kill_task
    )
    |> Enum.flat_map(fn
      {:ok, option} -> [option]
      {:exit, _} -> []
    end)
    |> Enum.sort_by(&String.downcase(&1.label))
  end

  defp to_option(ex) do
    %{
      label: exercise_label(ex),
      value: encode_exercise(ex),
      exercise_id: ex.exercise_id,
      custom_name: ex.custom_name
    }
  end

  defp exercise_label(%{exercise_id: nil, custom_name: name}), do: name

  defp exercise_label(%{exercise_id: id}) do
    case ExerciseCache.get_exercise(id) do
      {:ok, %{"name" => name}} when is_binary(name) and name != "" -> name
      _ -> id
    end
  end

  defp encode_exercise(%{exercise_id: nil, custom_name: name}), do: "custom:" <> name
  defp encode_exercise(%{exercise_id: id}), do: "id:" <> id

  defp find_exercise(value, options) when is_binary(value),
    do: Enum.find(options, &(&1.value == value))

  defp find_exercise(_value, _options), do: nil

  # Only accept plan ids the user actually belongs to, so the param can't be used
  # to peek at another group's leaderboard.
  defp parse_plan_id(raw, plans) do
    with raw when is_binary(raw) <- raw,
         {id, ""} <- Integer.parse(raw),
         true <- id in Enum.map(plans, & &1.id) do
      id
    else
      _ -> nil
    end
  end

  defp scope_params(plan_id, exercise, period) do
    [period: period]
    |> maybe_put(:plan_id, plan_id)
    |> maybe_put(:exercise, exercise)
  end

  defp maybe_put(params, _key, value) when value in [nil, ""], do: params
  defp maybe_put(params, key, value), do: params ++ [{key, value}]
end
