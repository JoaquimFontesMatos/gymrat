defmodule GymratWeb.WeightLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.UserWeights

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">
        {@user.name}'s Weight Progress
      </h1>

      <div class="flex flex-col gap-6">
        <div
          id="chart-loader"
          phx-hook="ChartLoader"
          class="flex flex-col md:flex-row gap-4 justify-center items-center w-full order-last md:order-first"
        >
          <div>
            <canvas
              :if={@weight_chart_data}
              id="weightProgressChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@weight_chart_data)}
              data-y-axis-title="Weight (Kg)"
            >
            </canvas>
          </div>
        </div>
        <ul class="order-first md:order-last">
          <%= for weight <- @weights do %>
            <li class="mb-2 p-2 border rounded flex justify-between items-center">
              <span>
                <strong>Weight:</strong> {weight.weight} kg
              </span>

              <div class="join">
                <.button
                  class="btn btn-primary btn-soft btn-square join-item"
                  phx-click="update_weight"
                  phx-value-weight-id={weight.id}
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
                  class="btn btn-error btn-soft btn-square join-item"
                  phx-click="show_modal_weight"
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
                  :if={@show_modal_weight}
                  id="confirm-modal_weight"
                  on_cancel={JS.push("hide_modal")}
                >
                  <h2>Are you sure you want to delete this weight?</h2>
                  <p>This action cannot be undone.</p>
                  <div class="modal-action">
                    <.button phx-click="hide_modal_weight">
                      Cancel
                    </.button>
                    <.button
                      class="btn btn-error"
                      phx-click="delete_weight"
                      phx-value-weight-id={weight.id}
                    >
                      Confirm
                    </.button>
                  </div>
                </.modal>
              </div>
            </li>
          <% end %>

          <%= if Enum.empty?(@weights) do %>
            <p>
              No weight measurement was saved today.
              <a
                class="underline hover:text-secondary"
                href={~p"/weights/new"}
              >
                Save one!
              </a>
            </p>
          <% else %>
            <.button phx-click="add_weight" class="btn btn-primary w-full">
              Save another
            </.button>
          <% end %>
        </ul>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        _payload,
        _session,
        socket
      ) do
    user = socket.assigns.current_scope.user

    weights = UserWeights.get_todays_user_weights(user.id)

    {:ok,
     socket
     |> assign(:weights, weights)
     |> assign(:user, user)
     |> assign(:show_modal_weight, false)
     |> assign(:weight_chart_data, nil)
     |> push_event("load_chart_data", %{})}
  end

  defp build_weight_chart_data(user_id) do
    daily_weight = UserWeights.get_weights_by_insertdate(user_id)

    # Build weight chart data
    weight_labels = Enum.map(daily_weight, &Calendar.strftime(&1.inserted_at, "%d-%m-%y %H:%M"))
    weight_data = Enum.map(daily_weight, & &1.weight)

    %{
      labels: weight_labels,
      datasets: [
        %{
          label: "Weight Progress (kg)",
          data: weight_data,
          borderColor: "rgb(59, 130, 246)",
          backgroundColor: "rgba(59, 130, 246, 0.2)",
          fill: true
        }
      ]
    }
  end

  @impl true
  def handle_event("load_chart_data", _params, socket) do
    user = socket.assigns.current_scope.user

    weight_chart_data = build_weight_chart_data(user.id)

    {:noreply,
     socket
     |> assign(:weight_chart_data, weight_chart_data)}
  end

  @impl true
  def handle_event("add_weight", _payload, socket) do
    {
      :noreply,
      socket
      |> push_navigate(to: ~p"/weights/new")
    }
  end

  @impl true
  def handle_event("show_modal_weight", _params, socket) do
    {:noreply, assign(socket, :show_modal_weight, true)}
  end

  @impl true
  def handle_event("hide_modal_weight", _params, socket) do
    {:noreply, assign(socket, :show_modal_weight, false)}
  end

  @impl true
  def handle_event("delete_weight", %{"weight-id" => weight_id}, socket) do
    case UserWeights.get_user_weight(weight_id) do
      {:ok, weight} ->
        case UserWeights.soft_delete_user_weight(weight) do
          {:ok, _} ->
            {
              :noreply,
              socket
              |> put_flash(
                :info,
                "The weight was deleted!"
              )
              |> push_navigate(to: ~p"/weights")
            }

          {:error, _} ->
            {
              :noreply,
              socket
              |> put_flash(
                :error,
                "Failed to delete the weight!"
              )
            }
        end

      {:error, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :error,
            :not_found
          )
        }
    end
  end

  @impl true
  def handle_event("update_weight", %{"weight-id" => weight_id}, socket) do
    {
      :noreply,
      socket
      |> push_navigate(to: ~p"/weights/#{weight_id}/edit")
    }
  end
end
