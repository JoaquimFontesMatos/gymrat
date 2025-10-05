defmodule GymratWeb.ExerciseLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.WorkoutExercises
  alias Gymrat.Training.Sets
  alias Gymrat.ExerciseFetcher

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

    daily_reps = Sets.get_set_sum_reps_by_day(exercise_id, user.id)
    # Build reps chart data
    reps_labels = Enum.map(daily_reps, &Calendar.strftime(&1.day, "%d-%m-%y"))
    reps_data = Enum.map(daily_reps, & &1.total_reps)

    daily_weight = Sets.get_set_sum_weight_by_day(exercise_id, user.id)
    # Build weight chart data
    weight_labels = Enum.map(daily_weight, &Calendar.strftime(&1.day, "%d-%m-%y"))
    weight_data = Enum.map(daily_weight, & &1.total_weight)

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

    {:ok,
     assign(socket,
       plan_id: plan_id,
       workout_id: workout_id,
       exercise: exercise,
       fetched_exercise: fetched_exercise,
       weight_chart_data: weight_chart_data,
       reps_chart_data: reps_chart_data,
       show_modal_set: false,
       show_modal_exercise: false,
       is_workout_exercise_from_user: is_workout_exercise_from_user
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
