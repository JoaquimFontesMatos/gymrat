defmodule GymratWeb.PlanLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.Plans
  alias Gymrat.Training.Workouts
  import GymratWeb.MyComponents

  defp get_localized_weekdays(weekdays) when is_list(weekdays) do
    case weekdays do
      [] ->
        "No weekday"

      _ ->
        weekdays
        |> Enum.map(&weekday_to_string(&1.weekday))
        |> Enum.join(", ")
    end
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
      <.header_with_back_navigate navigate={~p"/"} title={@plan.name} />

      <ul>
        <%= for workout <- @plan.workouts do %>
          <.list_item navigate={~p"/plans/#{workout.plan_id}/workouts/#{workout.id}"}>
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
              class="lucide lucide-dumbbell-icon lucide-dumbbell size-[1.2em] shrink-0"
            >
              <path d="M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828l-1.767-1.768a2 2 0 1 0-2.829 2.829z" /><path d="m2.5 21.5 1.4-1.4" /><path d="m20.1 3.9 1.4-1.4" /><path d="M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829l1.768 1.767a2 2 0 0 0-2.828 2.829z" /><path d="m9.6 14.4 4.8-4.8" />
            </svg>
            <div class="pl-2 flex flex-col justify-start text-start">
              <span>{workout.name}</span>
              <span class="text-gray-500 text-xs h-full">
                {get_localized_weekdays(Workouts.get_workout_weekdays(workout.id))}
              </span>
            </div>
          </.list_item>
        <% end %>

        <%= if Enum.empty?(@plan.workouts) do %>
          <p>
            No workouts created yet.
            <a
              :if={@current_user_id == @plan.creator_id}
              class="underline hover:text-secondary"
              href={~p"/plans/#{@plan.id}/workouts/new"}
            >
              Create one!
            </a>
          </p>
        <% else %>
          <.button
            :if={@current_user_id == @plan.creator_id}
            phx-click="create_workout"
            class="btn btn-primary w-full"
          >
            Create a Workout
          </.button>
        <% end %>
      </ul>

      <div class="flex justify-end flex-wrap gap-2" phx-hook="Share" id="plan-actions">
        <.button
          class="btn btn-primary btn-soft btn-square"
          phx-click={
            JS.dispatch("share-plan",
              detail: %{share_token: @plan.share_token, name: @plan.name},
              to: "#plan-actions"
            )
          }
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="size-6"
          >
            <path
              fill-rule="evenodd"
              d="M15.75 4.5a3 3 0 1 1 .825 2.066l-8.421 4.679a3.002 3.002 0 0 1 0 1.51l8.421 4.679a3 3 0 1 1-.729 1.31l-8.421-4.678a3 3 0 1 1 0-4.132l8.421-4.679a3 3 0 0 1-.096-.755Z"
              clip-rule="evenodd"
            />
          </svg>
        </.button>

        <.button
          :if={@current_user_id == @plan.creator_id}
          phx-click="update_plan"
          class="btn btn-primary btn-soft btn-square"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="size-[1.2em]"
          >
            <path d="M21.731 2.269a2.625 2.625 0 0 0-3.712 0l-1.157 1.157 3.712 3.712 1.157-1.157a2.625 2.625 0 0 0 0-3.712ZM19.513 8.199l-3.712-3.712-12.15 12.15a5.25 5.25 0 0 0-1.32 2.214l-.8 2.685a.75.75 0 0 0 .933.933l2.685-.8a5.25 5.25 0 0 0 2.214-1.32L19.513 8.2Z" />
          </svg>
        </.button>

        <.button
          phx-click="show_modal"
          class="btn btn-error btn-soft btn-square"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="size-[1.2em]"
          >
            <path
              fill-rule="evenodd"
              d="M16.5 4.478v.227a48.816 48.816 0 0 1 3.878.512.75.75 0 1 1-.256 1.478l-.209-.035-1.005 13.07a3 3 0 0 1-2.991 2.77H8.084a3 3 0 0 1-2.991-2.77L4.087 6.66l-.209.035a.75.75 0 0 1-.256-1.478A48.567 48.567 0 0 1 7.5 4.705v-.227c0-1.564 1.213-2.9 2.816-2.951a52.662 52.662 0 0 1 3.369 0c1.603.051 2.815 1.387 2.815 2.951Zm-6.136-1.452a51.196 51.196 0 0 1 3.273 0C14.39 3.05 15 3.684 15 4.478v.113a49.488 49.488 0 0 0-6 0v-.113c0-.794.609-1.428 1.364-1.452Zm-.355 5.945a.75.75 0 1 0-1.5.058l.347 9a.75.75 0 1 0 1.499-.058l-.346-9Zm5.48.058a.75.75 0 1 0-1.498-.058l-.347 9a.75.75 0 0 0 1.5.058l.345-9Z"
              clip-rule="evenodd"
            />
          </svg>
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
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => plan_id}, _session, socket) do
    current_user_id = socket.assigns.current_scope.user.id
    # Convert ID from URL param
    plan_id = String.to_integer(plan_id)

    # Fetch workouts for this plan
    case Workouts.get_plan_with_workouts(plan_id) do
      {:ok, plan} ->
        {:ok, assign(socket, plan: plan, show_modal: false, current_user_id: current_user_id)}

      {:error, _reason} ->
        {:error, :not_found}
    end
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
    plan = socket.assigns.plan
    user = socket.assigns.current_scope.user

    case Plans.get_user_plan(user.id, plan.id) do
      {:ok, user_plan} ->
        if plan.creator_id == user.id do
          case Plans.soft_delete_plan(plan, user_plan) do
            {:ok, _} ->
              {
                :noreply,
                socket
                |> put_flash(:info, "The plan was deleted!")
                |> push_navigate(to: ~p"/")
              }

            {:error, _} ->
              {
                :noreply,
                socket
                |> put_flash(:error, "Failed to delete the plan!")
              }
          end
        else
          case Plans.soft_delete_user_plan(user_plan) do
            {:ok, _} ->
              {
                :noreply,
                socket
                |> put_flash(:info, "The plan was desassociated!")
                |> push_navigate(to: ~p"/")
              }

            {:error, _} ->
              {
                :noreply,
                socket
                |> put_flash(:error, "Failed to desassociate the plan!")
              }
          end
        end

      {:error, _} ->
        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to find the associated plan!")
        }
    end
  end
end
