defmodule GymratWeb.PlanLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.Plans
  alias Gymrat.Training.Workouts

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
              <.button phx-click="go_to_workout" phx-value-workout-id={workout.id}>
                Details
              </.button>
            </div>
          </li>
        <% end %>

        <%= if Enum.empty?(@plan.workouts) do %>
          <p>
            No workouts created yet.
            <a class="underline hover:text-blue-500" href={~p"/plans/#{@plan.id}/workouts/new"}>
              Create one!
            </a>
          </p>
        <% else %>
          <.button phx-click="create_workout" class="btn btn-primary w-full">
            Create a Workout
          </.button>
        <% end %>
      </ul>

      <div class="flex justify-end flex-wrap">
        <.button phx-click="update_plan">
          Update
        </.button>

        <.button class="btn btn-error" phx-click="show_modal">
          Delete
        </.button>

        <.modal
          :if={@show_modal}
          id="confirm-modal"
          on_cancel={JS.push("hide_modal")}
        >
          <h2>Are you sure you want to delete this plan?</h2>
          <p>This action cannot be undone.</p>
          <div class="modal-action">
            <.button phx-click="hide_modal">
              Cancel
            </.button>
            <.button class="btn btn-error" phx-click="delete_plan">
              Confirm
            </.button>
          </div>
        </.modal>
      </div>

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
    plan = Workouts.get_plan_with_workouts(plan_id)

    {:ok, assign(socket, plan: plan, show_modal: false)}
  end

  # Event to show the modal
  @impl true
  def handle_event("show_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  # Event to hide the modal
  @impl true
  def handle_event("hide_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
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

  @impl true
  def handle_event("update_plan", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(to: ~p"/plans/#{socket.assigns.plan.id}/edit")
    }
  end

  @impl true
  def handle_event("delete_plan", _payload, socket) do
    case Plans.soft_delete_plan(socket.assigns.plan) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The plan was deleted!"
          )
          |> push_navigate(to: ~p"/")
        }

      {:error, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :error,
            "Failed to delete the plan!"
          )
        }
    end
  end

  @impl true
  def handle_event("go_to_workout", %{"workout-id" => workout_id}, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(to: ~p"/plans/#{socket.assigns.plan.id}/workouts/#{workout_id}")
    }
  end
end
