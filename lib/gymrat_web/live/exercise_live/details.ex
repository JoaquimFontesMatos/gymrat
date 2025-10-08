defmodule GymratWeb.ExerciseLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.WorkoutExercises
  alias Gymrat.Training.Sets
  alias Gymrat.ExerciseFetcher

  @colors [
    # red
    %{border: "rgba(239, 68, 68, 0.7)", background: "rgba(239, 68, 68, 0.2)"},
    # green
    %{border: "rgba(34, 197, 94, 0.7)", background: "rgba(34, 197, 94, 0.2)"},
    # blue
    %{border: "rgba(59, 130, 246, 0.7)", background: "rgba(59, 130, 246, 0.2)"},
    # yellow
    %{border: "rgba(234, 179, 8, 0.7)", background: "rgba(234, 179, 8, 0.2)"},
    # purple
    %{border: "rgba(168, 85, 247, 0.7)", background: "rgba(168, 85, 247, 0.2)"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">
        {@fetched_exercise["name"]}
      </h1>

      <div class="collapse bg-secondary text-secondary-content border-primary border border-4">
        <input type="checkbox" class="peer" />
        <div class="collapse-title font-semibold">Details</div>
        <div class="collapse-content text-sm bg-primary text-primary-content peer-checked:bg-neutral peer-checked:text-neutral-content">
          <div class="flex flex-col gap-4">
            <img
              loading="lazy"
              src={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{@fetched_exercise["id"] }/0.jpg"}
              data-png={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{@fetched_exercise["id"] }/0.png"}
              data-webp={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{@fetched_exercise["id"] }/0.webp"}
              alt="Exercise Image"
              class="w-full h-56 object-cover"
              onerror="this.onerror=null; if(this.src.endsWith('.jpg')) {this.src=this.dataset.png;} else if(this.src.endsWith('.png')) {this.src=this.dataset.webp;} else {this.src='/images/default_exercise.jpg';}"
            />
            <p>
              <strong>Primary Muscles:</strong>
              {Enum.join(List.wrap(@fetched_exercise["primaryMuscles"] || []), ", ")}
            </p>
            <p>
              <strong>Secondary Muscles:</strong>
              {Enum.join(List.wrap(@fetched_exercise["secondaryMuscles"] || []), ", ")}
            </p>
            <p>
              <strong>Level:</strong>
              <span class={"px-2 py-1 rounded "<>
                case @fetched_exercise["level"] do
                "beginner" -> "bg-green-200 text-green-800"
                "intermediate" -> "bg-yellow-200 text-yellow-800"
                "expert" -> "bg-red-200 text-red-800"
                _ -> "bg-gray-200 text-gray-600"
                end
                }>
                {@fetched_exercise["level"] || "N/A"}
              </span>
            </p>
            <p><strong>Category:</strong> {@fetched_exercise["category"] || "N/A"}</p>
            <p><strong>Equipment:</strong> {@fetched_exercise["equipment"] || "N/A"}</p>
            <p><strong>Force:</strong> {@fetched_exercise["force"] || "N/A"}</p>
            <div>
              <strong>Instructions:</strong>
              <ol class="ml-4">
                <li :for={instruction <- @fetched_exercise["instructions"] || []} class="list-decimal">
                  {instruction}
                </li>
              </ol>
            </div>
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-6">
        <div
          id="chart-loader"
          phx-hook="ChartLoader"
          class="flex flex-col md:flex-row gap-4 justify-center items-center w-full order-last md:order-first"
        >
          <div>
            <canvas
              :if={@reps_chart_data}
              id="repsProgressChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@reps_chart_data)}
              data-y-axis-title="Reps"
            >
            </canvas>
          </div>
          <div>
            <canvas
              :if={@weight_chart_data}
              id="weightProgressChart"
              phx-hook="Chart"
              data-chart={Jason.encode!(@weight_chart_data)}
              data-y-axis-title="Weight (kg)"
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

              <div class="flex justify-end flex-wrap">
                <.button phx-click="update_set" phx-value-set-id={set.id}>
                  Update
                </.button>

                <.button class="btn btn-error" phx-click="show_modal_set">
                  Delete
                </.button>

                <.modal
                  :if={@show_modal_set}
                  id="confirm-modal_set"
                  on_cancel={JS.push("hide_modal")}
                >
                  <h2>Are you sure you want to delete this set?</h2>
                  <p>This action cannot be undone.</p>
                  <div class="modal-action">
                    <.button phx-click="hide_modal_set">
                      Cancel
                    </.button>
                    <.button class="btn btn-error" phx-click="delete_set" phx-value-set-id={set.id}>
                      Confirm
                    </.button>
                  </div>
                </.modal>
              </div>
            </li>
          <% end %>

          <%= if Enum.empty?(@exercise.sets) do %>
            <p>
              No sets added yet.
              <a
                class="underline hover:text-secondary"
                href={
                  ~p"/plans/#{@plan_id}/workouts/#{@workout_id}/exercises/#{@exercise.id}/sets/new"
                }
              >
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

      <div class="flex justify-end flex-wrap">
        <.button
          :if={@is_workout_exercise_from_user}
          class="btn btn-error"
          phx-click="show_modal_exercise"
        >
          Delete
        </.button>

        <.modal
          :if={@show_modal_exercise}
          id="confirm-modal_exercise"
          on_cancel={JS.push("hide_modal")}
        >
          <h2>Are you sure you want to delete this exercise?</h2>
          <p>This action cannot be undone.</p>
          <div class="modal-action">
            <.button phx-click="hide_modal_exercise">
              Cancel
            </.button>
            <.button class="btn btn-error" phx-click="delete_exercise">
              Confirm
            </.button>
          </div>
        </.modal>
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
    user = socket.assigns.current_scope.user

    # Convert ID from URL param
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)
    exercise_id = String.to_integer(exercise_id)

    is_workout_exercise_from_user =
      WorkoutExercises.is_workout_exercise_from_user(exercise_id, user.id)

    exercise = Sets.get_todays_workout_exercise_with_sets(exercise_id, user.id)
    {:ok, fetched_exercise} = ExerciseFetcher.fetch_exercise(exercise.exercise_id)

    {:ok,
     socket
     |> assign(:plan_id, plan_id)
     |> assign(:workout_id, workout_id)
     |> assign(:exercise, exercise)
     |> assign(:fetched_exercise, fetched_exercise)
     |> assign(:show_modal_set, false)
     |> assign(:show_modal_exercise, false)
     |> assign(:is_workout_exercise_from_user, is_workout_exercise_from_user)
     |> assign(:weight_chart_data, nil)
     |> assign(:reps_chart_data, nil)
     |> push_event("load_chart_data", %{})}
  end

  defp build_weight_chart_data(exercise_id, user_id) do
    weight_by_day = Sets.get_sets_weight_by_day(exercise_id, user_id)

    # Group sets by day
    grouped_weight_by_day = Enum.group_by(weight_by_day, & &1.day)

    # Assign index to each set per day
    indexed_weight_sets =
      grouped_weight_by_day
      |> Enum.flat_map(fn {day, sets} ->
        Enum.with_index(sets, fn set, idx ->
          %{day: day, index: idx, weight: set.weight}
        end)
      end)

    # Group by set index
    grouped_weight_by_index = Enum.group_by(indexed_weight_sets, & &1.index)
    weight_raw_days = grouped_weight_by_day |> Map.keys() |> Enum.sort()
    weight_labels = Enum.map(weight_raw_days, &Calendar.strftime(&1, "%d-%m-%y"))

    weight_datasets =
      Enum.map(grouped_weight_by_index, fn {index, sets} ->
        weights_by_day = Map.new(sets, fn %{day: day, weight: weight} -> {day, weight} end)
        # fallback to last color if index exceeds
        color = Enum.at(@colors, index, List.last(@colors))

        %{
          label: "Set #{index + 1}",
          data:
            Enum.map(weight_raw_days, fn day ->
              Map.get(weights_by_day, day, nil)
            end),
          borderColor: color.border,
          backgroundColor: color.background,
          fill: false,
          tension: 0.3
        }
      end)

    %{
      labels: weight_labels,
      datasets: weight_datasets
    }
  end

  defp build_reps_chart_data(exercise_id, user_id) do
    reps_by_day = Sets.get_sets_reps_by_day(exercise_id, user_id)

    # Group sets by day
    grouped_reps_by_day = Enum.group_by(reps_by_day, & &1.day)

    # Assign index to each set per day
    indexed_reps_sets =
      grouped_reps_by_day
      |> Enum.flat_map(fn {day, sets} ->
        Enum.with_index(sets, fn set, idx ->
          %{day: day, index: idx, reps: set.reps}
        end)
      end)

    # Group by set index
    grouped_reps_by_index = Enum.group_by(indexed_reps_sets, & &1.index)
    reps_raw_days = grouped_reps_by_day |> Map.keys() |> Enum.sort()
    reps_labels = Enum.map(reps_raw_days, &Calendar.strftime(&1, "%d-%m-%y"))

    reps_datasets =
      Enum.map(grouped_reps_by_index, fn {index, sets} ->
        reps_by_day = Map.new(sets, fn %{day: day, reps: reps} -> {day, reps} end)
        # fallback to last color if index exceeds
        color = Enum.at(@colors, index, List.last(@colors))

        %{
          label: "Set #{index + 1}",
          data:
            Enum.map(reps_raw_days, fn day ->
              Map.get(reps_by_day, day, nil)
            end),
          borderColor: color.border,
          backgroundColor: color.background,
          fill: false,
          tension: 0.3
        }
      end)

    %{
      labels: reps_labels,
      datasets: reps_datasets
    }
  end

  @impl true
  def handle_event("load_chart_data", _params, socket) do
    user = socket.assigns.current_scope.user
    exercise_id = socket.assigns.exercise.id

    weight_chart_data = build_weight_chart_data(exercise_id, user.id)
    reps_chart_data = build_reps_chart_data(exercise_id, user.id)

    {:noreply,
     socket
     |> assign(:weight_chart_data, weight_chart_data)
     |> assign(:reps_chart_data, reps_chart_data)}
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

  @impl true
  def handle_event("show_modal_set", _params, socket) do
    {:noreply, assign(socket, :show_modal_set, true)}
  end

  # Event to hide the modal
  @impl true
  def handle_event("hide_modal_set", _params, socket) do
    {:noreply, assign(socket, :show_modal_set, false)}
  end

  @impl true
  def handle_event("show_modal_exercise", _params, socket) do
    {:noreply, assign(socket, :show_modal_exercise, true)}
  end

  # Event to hide the modal
  @impl true
  def handle_event("hide_modal_exercise", _params, socket) do
    {:noreply, assign(socket, :show_modal_exercise, false)}
  end

  @impl true
  def handle_event("delete_exercise", _payload, socket) do
    case WorkoutExercises.soft_delete_workout_exercise(socket.assigns.exercise) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The exercise was deleted!"
          )
          |> push_navigate(
            to: ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}"
          )
        }

      {:error, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :error,
            "Failed to delete the exercise!"
          )
        }
    end
  end

  @impl true
  def handle_event("delete_set", %{"set-id" => set_id}, socket) do
    case Sets.get_set(set_id) do
      {:ok, set} ->
        case Sets.soft_delete_set(set) do
          {:ok, _} ->
            {
              :noreply,
              socket
              |> put_flash(
                :info,
                "The set was deleted!"
              )
              |> push_navigate(
                to:
                  ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{socket.assigns.exercise.id}"
              )
            }

          {:error, _} ->
            {
              :noreply,
              socket
              |> put_flash(
                :error,
                "Failed to delete the set!"
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
  def handle_event("update_set", %{"set-id" => set_id}, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to:
          ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{socket.assigns.exercise.id}/sets/#{set_id}/edit"
      )
    }
  end
end
