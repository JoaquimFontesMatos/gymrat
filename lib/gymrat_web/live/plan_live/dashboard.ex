defmodule GymratWeb.PlanLive.Dashboard do
  use GymratWeb, :live_view

  alias Gymrat.Training.Plans
  alias Gymrat.Training.Workouts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">Today's Workouts</h1>

      <ul class="list-disc pl-4">
        <%= for workout <- @todays_workouts do %>
          <li class="mb-2 p-2 border rounded flex justify-between items-center">
            <span>{workout.name}</span>
            <div>
              <.button
                phx-click="go_to_workout"
                phx-value-workout-id={workout.id}
                phx-value-plan-id={workout.plan_id}
              >
                Details
              </.button>
            </div>
          </li>
        <% end %>

        <%= if Enum.empty?(@todays_workouts) do %>
          <p>
            No workouts today.
          </p>
        <% end %>
      </ul>
      <h1 class="text-2xl font-bold mt-16">{@current_scope.user.name}'s Plans</h1>

      <ul class="list-disc pl-4">
        <%= for plan <- @plans do %>
          <li class="mb-2 p-2 border rounded flex justify-between items-center">
            <span>{plan.name}</span>
            <div>
              <.button phx-click="go_to_plan" phx-value-plan-id={plan.id}>
                Details
              </.button>
            </div>
          </li>
        <% end %>

        <%= if Enum.empty?(@plans) do %>
          <p>
            No plans created yet.
            <a class="underline hover:text-blue-500" href={~p"/plans/new"}>Create one!</a>
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

  # If using the phx-click="go_to_plan" event
  @impl true
  def handle_event("go_to_plan", %{"plan-id" => plan_id}, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(to: ~p"/plans/#{plan_id}")
    }
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

  @impl true
  def handle_event("go_to_workout", %{"workout-id" => workout_id, "plan-id" => plan_id}, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(to: ~p"/plans/#{plan_id}/workouts/#{workout_id}")
    }
  end
end
