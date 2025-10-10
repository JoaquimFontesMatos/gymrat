defmodule GymratWeb.ScoreboardLive.VolumeScoreboard do
  use GymratWeb, :live_view

  alias Gymrat.Training.Sets

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">
        Weekly Scoreboard
      </h1>

      <ul class="list-disc pl-4 order-first md:order-last">
        <%= for user_volume <- @weekly_volume do %>
          <li class="mb-2 p-2 border rounded flex justify-between items-center">
            <span>
              <strong>Volume:</strong> {user_volume.current_week_volume} kg
              <strong>User:</strong> {user_volume.user_id}
            </span>
          </li>
        <% end %>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        _payload,
        _session,
        socket
      ) do
    weekly_volume = Sets.get_weekly_training_volume()

    {:ok,
     socket
     |> assign(:weekly_volume, weekly_volume)}
  end
end
