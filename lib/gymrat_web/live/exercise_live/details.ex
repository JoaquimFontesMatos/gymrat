defmodule GymratWeb.ExerciseLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1>
        {@exercise.exercise_id
        |> String.replace("_", " ")
        |> String.capitalize()}
      </h1>

      <div class="flex flex-col gap-6">
        <div class="flex flex-col md:flex-row gap-4 justify-center items-center w-full order-last md:order-first">
          <div>
            <canvas
              id="repsProgressChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@reps_chart_data)}
            >
            </canvas>
          </div>
          <div>
            <canvas
              id="weightProgressChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@weight_chart_data)}
            >
            </canvas>
          </div>
        </div>
        <ul class="list-disc pl-4 order-first md:order-last">
          <%= for set <- @exercise.sets do %>
            <li class="mb-2 p-2 border rounded flex justify-between items-center">
              <span>
                <strong>Weight:</strong> {set.weight} kg &nbsp; | &nbsp;
                <strong>Reps:</strong> {set.reps}
              </span>
            </li>
          <% end %>

          <%= if Enum.empty?(@exercise.sets) do %>
            <p>
              No sets added yet.
              <a href={
                ~p"/plans/#{@plan_id}/workouts/#{@workout_id}/exercises/#{@exercise.id}/sets/new"
              }>
                Add one!
              </a>
            </p>
          <% else %>
            <.button phx-click="add_set" class="btn btn-primary w-full">
              Add a Set
            </.button>
          <% end %>
        </ul>
      </div>

      <.button phx-click="back_to_workout">
        Back to Workout
      </.button>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        %{"plan_id" => plan_id, "workout_id" => workout_id, "exercise_id" => exercise_id},
        _session,
        socket
      ) do
    # Convert ID from URL param
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)
    exercise_id = String.to_integer(exercise_id)

    exercise = Training.get_todays_workout_exercise_with_sets(exercise_id)

    daily_weight = Training.get_set_sum_weight_by_day(exercise_id)
    # Build chart data
    weight_labels = Enum.map(daily_weight, &Calendar.strftime(&1.day, "%d-%m-%y"))
    weight_data = Enum.map(daily_weight, & &1.total_weight)

    daily_reps = Training.get_set_sum_reps_by_day(exercise_id)
    # Build chart data
    reps_labels = Enum.map(daily_reps, &Calendar.strftime(&1.day, "%d-%m-%y"))
    reps_data = Enum.map(daily_reps, & &1.total_reps)

    weight_chart_data = %{
      labels: weight_labels,
      datasets: [
        %{
          label: "Daily Weight Volume (kg)",
          data: weight_data,
          borderColor: "rgb(59, 130, 246)",
          backgroundColor: "rgba(59, 130, 246, 0.2)",
          fill: true,
          tension: 0.3
        }
      ]
    }

    reps_chart_data = %{
      labels: reps_labels,
      datasets: [
        %{
          label: "Daily Reps Volume (kg)",
          data: reps_data,
          borderColor: "rgb(59, 130, 246)",
          backgroundColor: "rgba(59, 130, 246, 0.2)",
          fill: true,
          tension: 0.3
        }
      ]
    }

    {:ok,
     assign(socket,
       plan_id: plan_id,
       workout_id: workout_id,
       exercise: exercise,
       weight_chart_data: weight_chart_data,
       reps_chart_data: reps_chart_data
     )}
  end

  @impl true
  def handle_event("back_to_workout", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to: ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}"
      )
    }
  end

  @impl true
  def handle_event("add_set", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to:
          ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{socket.assigns.exercise.id}/sets/new"
      )
    }
  end
end
