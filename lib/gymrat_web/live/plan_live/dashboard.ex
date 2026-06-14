defmodule GymratWeb.PlanLive.Dashboard do
  use GymratWeb, :live_view

  alias Gymrat.Training.Plans
  alias Gymrat.Training.Workouts
  import GymratWeb.MyComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="font-bold text-2xl">Today's Workouts</h1>

      <ul>
        <%= for workout <- @todays_workouts do %>
          <.list_item navigate={~p"/plans/#{workout.plan_id}/workouts/#{workout.id}"}>
            <.workout_icon name={resolve_icon(workout)} class="h-12 w-9 shrink-0 text-primary" />
            <span class="pl-2">
              {workout.name} <span class="opacity-50 text-sm">| {workout.plan.name}</span>
            </span>
          </.list_item>
        <% end %>

        <%= if Enum.empty?(@todays_workouts) do %>
          <p>
            No workouts today.
          </p>
        <% end %>
      </ul>
      <h1 class="mt-8 font-bold text-2xl">{@current_scope.user.name}'s Plans</h1>

      <ul>
        <%= for plan <- @plans do %>
          <.list_item navigate={~p"/plans/#{plan.id}"}>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="size-[1.2em] lucide-list-check lucide-list-check-icon lucide lucide-dumbbell"
            >
              <path d="M16 5H3" /><path d="M16 12H3" /><path d="M11 19H3" /><path d="m15 18 2 2 4-4" />
            </svg>

            <span class="pl-2">{plan.name}</span>
          </.list_item>
        <% end %>

        <%= if Enum.empty?(@plans) do %>
          <p>
            No plans created yet.
            <a class="hover:text-blue-500 underline" href={~p"/plans/new"}>Create one!</a>
          </p>
        <% end %>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    # `current_user` is already assigned by the on_mount hook
    plans = Plans.list_my_plans(user.id)

    date = Date.utc_today()
    weekday = Date.day_of_week(date)

    todays_workouts = Workouts.list_my_workouts_by_weekday(weekday, user.id)

    {:ok, assign(socket, plans: plans, todays_workouts: todays_workouts)}
  end

  @impl true
  def handle_event("create_plan", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(to: ~p"/plans/new")
    }
  end
end
