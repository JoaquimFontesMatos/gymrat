defmodule GymratWeb.WeightLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.UserWeights
  import GymratWeb.MyComponents

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
            <.list_item>
              <span>
                <strong>Weight:</strong> {weight.weight} kg
              </span>

              <.joined_action_group
                on_edit_navigate={~p"/weights/#{weight.id}/edit"}
                on_delete="delete_weight"
                resource_id={weight.id}
                show_modal={@show_modal_weight}
                resource_name="weight"
              >
                <:modal_content>
                  <h2>Are you sure you want to delete this measurement?</h2>
                  <p>This action cannot be undone.</p>
                </:modal_content>
              </.joined_action_group>
            </.list_item>
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
  def handle_event("delete_weight", %{"id" => weight_id}, socket) do
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
end
