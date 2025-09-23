# lib/gymrat_web/live/plan_live/show.ex (Example)
defmodule GymratWeb.PlanLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1>{@plan.name}</h1>

      <ul class="list-disc pl-4">
        <%= for workout <- @plan.workouts do %>
          <li class="mb-2 p-2 border rounded flex justify-between items-center">
            <span>{workout.name}</span>
            <div>
              <.button phx-click="go_to_workout" phx-value-plan-id={workout.id}>
                Details
              </.button>
            </div>
          </li>
        <% end %>

        <%= if Enum.empty?(@plan.workouts) do %>
          <p>
            No workouts created yet. <a href={~p"/plans/#{@plan.id}/workouts/new"}>Create one!</a>
          </p>
        <% else %>
          <.button phx-click="create_workout" class="btn btn-primary w-full">
            Create a Workout
          </.button>
        <% end %>
      </ul>

      <.button phx-click="back_to_dashboard">
        Back to Dashboard
      </.button>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => plan_id}, _session, socket) do
    # Convert ID from URL param
    plan_id = String.to_integer(plan_id)

    # Fetch workouts for this plan
    plan = Training.get_plan_with_workouts(plan_id)

    {:ok, assign(socket, plan: plan)}
  end

  @impl true
  def handle_event("back_to_dashboard", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(to: ~p"/")
    }
  end

  @impl true
  def handle_event("create_workout", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(to: ~p"/plans/#{socket.assigns.plan.id}/workouts/new")
    }
  end
end
