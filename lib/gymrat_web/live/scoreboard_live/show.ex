defmodule GymratWeb.ScoreboardLive.Show do
  use GymratWeb, :live_view

  alias Gymrat.Training.{Plans, Sets}
  import GymratWeb.MyComponents

  @periods %{"weekly" => :weekly, "monthly" => :monthly, "all_time" => :all_time}
  @titles %{
    weekly: "Weekly Scoreboard",
    monthly: "Monthly Scoreboard",
    all_time: "All-Time Scoreboard"
  }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/"}
        title={@title}
      />

      <form :if={@plans != []} id="scope-form" phx-change="select_scope" class="mb-4">
        <label class="flex items-center gap-2">
          <.icon name="hero-user-group" class="h-5 w-5 shrink-0 text-base-content/60" />
          <select
            name="plan_id"
            class="select select-bordered w-full"
            aria-label="Leaderboard group"
          >
            <option value="" selected={is_nil(@selected_plan_id)}>Everyone</option>
            <option :for={plan <- @plans} value={plan.id} selected={@selected_plan_id == plan.id}>
              {plan.name}
            </option>
          </select>
        </label>
      </form>

      <div role="tablist" class="tabs tabs-boxed mb-4">
        <.link
          :for={
            {label, period} <- [{"Weekly", :weekly}, {"Monthly", :monthly}, {"All-Time", :all_time}]
          }
          patch={~p"/scoreboard?#{scope_params(@selected_plan_id, period)}"}
          role="tab"
          class={"tab " <> if(@period == period, do: "tab-active", else: "")}
        >
          {label}
        </.link>
      </div>

      <.link navigate={~p"/scoreboard/exercise"} class="btn btn-soft btn-sm mb-4">
        <.icon name="hero-trophy" class="h-4 w-4" /> Per-exercise board
      </.link>

      <.scoreboard_table
        value_header="Volume"
        rows={Enum.map(@volume, &%{user: &1.user, value: "#{round(&1.volume)} kg"})}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_payload, _session, socket) do
    plans = Plans.list_my_plans(socket.assigns.current_scope.user.id)
    {:ok, assign(socket, :plans, plans)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    period = Map.get(@periods, params["period"], :weekly)
    selected_plan_id = parse_plan_id(params["plan_id"], socket.assigns.plans)

    volume =
      if selected_plan_id do
        Sets.get_training_volume_for_plan(selected_plan_id, period)
      else
        Sets.get_training_volume(period)
      end

    {:noreply,
     socket
     |> assign(:period, period)
     |> assign(:selected_plan_id, selected_plan_id)
     |> assign(:title, @titles[period])
     |> assign(:volume, volume)}
  end

  @impl true
  def handle_event("select_scope", %{"plan_id" => plan_id}, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/scoreboard?#{scope_params(plan_id, socket.assigns.period)}")}
  end

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

  defp scope_params(plan_id, period) when plan_id in [nil, ""], do: [period: period]
  defp scope_params(plan_id, period), do: [period: period, plan_id: plan_id]
end
