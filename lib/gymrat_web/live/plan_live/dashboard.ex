defmodule GymratWeb.PlanLive.Dashboard do
  use GymratWeb, :live_view

  alias Gymrat.Training

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1>{@current_user.name}'s Plans</h1>

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
          <p>No plans created yet. <a href={~p"/plans/new"}>Create one!</a></p>
        <% else %>
          <.button phx-click="create_plan" class="btn btn-primary w-full">
            Create a Plan
          </.button>
        <% end %>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    # `current_user` is already assigned by the on_mount hook
    plans = Training.list_my_plans(user.id)
    {:ok, assign(socket, current_user: user, plans: plans)}
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
end
