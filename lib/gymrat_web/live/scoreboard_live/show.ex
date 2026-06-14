defmodule GymratWeb.ScoreboardLive.Show do
  use GymratWeb, :live_view

  alias Gymrat.Training.Sets
  import GymratWeb.MyComponents

  @periods %{"weekly" => :weekly, "monthly" => :monthly, "all_time" => :all_time}
  @titles %{
    weekly: "Weekly Scoreboard",
    monthly: "Monthly Scoreboard",
    all_time: "All-Time Scoreboard"
  }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/"}
        title={@title}
      />

      <div role="tablist" class="tabs tabs-boxed mb-4">
        <.link
          :for={
            {label, period} <- [{"Weekly", :weekly}, {"Monthly", :monthly}, {"All-Time", :all_time}]
          }
          patch={~p"/scoreboard?#{[period: period]}"}
          role="tab"
          class={"tab " <> if(@period == period, do: "tab-active", else: "")}
        >
          {label}
        </.link>
      </div>

      <div class="overflow-x-auto">
        <table class="table">
          <!-- head -->
          <thead>
            <tr>
              <th></th>
              <th>Name</th>
              <th>Volume</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <%= for {user_volume, index} <- Enum.with_index(@volume) do %>
              <tr class={"size-5 " <> rank_row_class(index)}>
                <th>{index + 1}</th>
                <td>{user_volume.user.name}</td>
                <td>{user_volume.volume} kg</td>
                <%= if index < 3 do %>
                  <td>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      class={"size-5 " <> medal_class(index)}
                    >
                      <path
                        fill-rule="evenodd"
                        d="M5.166 2.621v.858c-1.035.148-2.059.33-3.071.543a.75.75 0 0 0-.584.859 6.753 6.753 0 0 0 6.138 5.6 6.73 6.73 0 0 0 2.743 1.346A6.707 6.707 0 0 1 9.279 15H8.54c-1.036 0-1.875.84-1.875 1.875V19.5h-.75a2.25 2.25 0 0 0-2.25 2.25c0 .414.336.75.75.75h15a.75.75 0 0 0 .75-.75 2.25 2.25 0 0 0-2.25-2.25h-.75v-2.625c0-1.036-.84-1.875-1.875-1.875h-.739a6.706 6.706 0 0 1-1.112-3.173 6.73 6.73 0 0 0 2.743-1.347 6.753 6.753 0 0 0 6.139-5.6.75.75 0 0 0-.585-.858 47.077 47.077 0 0 0-3.07-.543V2.62a.75.75 0 0 0-.658-.744 49.22 49.22 0 0 0-6.093-.377c-2.063 0-4.096.128-6.093.377a.75.75 0 0 0-.657.744Zm0 2.629c0 1.196.312 2.32.857 3.294A5.266 5.266 0 0 1 3.16 5.337a45.6 45.6 0 0 1 2.006-.343v.256Zm13.5 0v-.256c.674.1 1.343.214 2.006.343a5.265 5.265 0 0 1-2.863 3.207 6.72 6.72 0 0 0 .857-3.294Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </td>
                <% else %>
                  <td></td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_payload, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    period = Map.get(@periods, params["period"], :weekly)

    {:noreply,
     socket
     |> assign(:period, period)
     |> assign(:title, @titles[period])
     |> assign(:volume, Sets.get_training_volume(period))}
  end

  defp rank_row_class(0), do: "text-yellow-500 bg-yellow-600/15"
  defp rank_row_class(1), do: "text-slate-500 bg-slate-600/15"
  defp rank_row_class(2), do: "text-amber-800 bg-amber-900/15"
  defp rank_row_class(_), do: ""

  defp medal_class(0), do: "text-yellow-500 stroke-yellow-600"
  defp medal_class(1), do: "text-slate-500 stroke-slate-600"
  defp medal_class(2), do: "text-amber-800 stroke-amber-900"
  defp medal_class(_), do: ""
end
