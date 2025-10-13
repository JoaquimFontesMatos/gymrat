defmodule GymratWeb.PlanLive.Dashboard do
  use GymratWeb, :live_view

  alias Gymrat.Training.Plans
  alias Gymrat.Training.Workouts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">Today's Workouts</h1>

      <ul>
        <%= for workout <- @todays_workouts do %>
          <li class="bg-base-100">
            <.button
              class="mb-2 border rounded flex justify-between items-center group w-full"
              phx-click="go_to_workout"
              phx-value-workout-id={workout.id}
              phx-value-plan-id={workout.plan_id}
              tabindex="0"
            >
              <div class="ml-2 flex justify-start items-center">
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
                  class="lucide lucide-dumbbell-icon lucide-dumbbellsize-[1.2em]"
                >
                  <path d="M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828l-1.767-1.768a2 2 0 1 0-2.829 2.829z" /><path d="m2.5 21.5 1.4-1.4" /><path d="m20.1 3.9 1.4-1.4" /><path d="M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829l1.768 1.767a2 2 0 0 0-2.828 2.829z" /><path d="m9.6 14.4 4.8-4.8" />
                </svg>
                <span class="p-2">{workout.name}</span>
              </div>
              <span class="p-2 opacity-0 w-0 group-active:bg-primary/50 group-active:opacity-100 group-active:w-[35%] group-hover:bg-primary/50 group-hover:opacity-100 group-hover:w-[35%] group-focus:bg-primary/50 group-focus:opacity-100 group-focus:w-[35%] transition-all duration-300 ease-in-out overflow-hidden">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  class="size-6"
                >
                  <path
                    fill-rule="evenodd"
                    d="M12.97 3.97a.75.75 0 0 1 1.06 0l7.5 7.5a.75.75 0 0 1 0 1.06l-7.5 7.5a.75.75 0 1 1-1.06-1.06l6.22-6.22H3a.75.75 0 0 1 0-1.5h16.19l-6.22-6.22a.75.75 0 0 1 0-1.06Z"
                    clip-rule="evenodd"
                  />
                </svg>
              </span>
            </.button>
          </li>
        <% end %>

        <%= if Enum.empty?(@todays_workouts) do %>
          <p>
            No workouts today.
          </p>
        <% end %>
      </ul>
      <h1 class="text-2xl font-bold mt-8">{@current_scope.user.name}'s Plans</h1>

      <ul>
        <%= for plan <- @plans do %>
          <li class="bg-base-100">
            <.button
              class="mb-2 border rounded flex justify-between items-center group w-full"
              phx-click="go_to_plan"
              phx-value-plan-id={plan.id}
              tabindex="0"
            >
              <div class="ml-2 flex justify-start items-center">
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
                  class="lucide lucide-list-check-icon lucide-list-check lucide-dumbbellsize-[1.2em]"
                >
                  <path d="M16 5H3" /><path d="M16 12H3" /><path d="M11 19H3" /><path d="m15 18 2 2 4-4" />
                </svg>

                <span class="p-2">{plan.name}</span>
              </div>
              <span class="p-2 opacity-0 w-0 group-active:bg-primary/50 group-active:opacity-100 group-active:w-[35%] group-hover:bg-primary/50 group-hover:opacity-100 group-hover:w-[35%] group-focus:bg-primary/50 group-focus:opacity-100 group-focus:w-[35%] transition-all duration-300 ease-in-out overflow-hidden">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  class="size-6"
                >
                  <path
                    fill-rule="evenodd"
                    d="M12.97 3.97a.75.75 0 0 1 1.06 0l7.5 7.5a.75.75 0 0 1 0 1.06l-7.5 7.5a.75.75 0 1 1-1.06-1.06l6.22-6.22H3a.75.75 0 0 1 0-1.5h16.19l-6.22-6.22a.75.75 0 0 1 0-1.06Z"
                    clip-rule="evenodd"
                  />
                </svg>
              </span>
            </.button>
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
