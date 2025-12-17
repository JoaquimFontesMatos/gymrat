defmodule GymratWeb.ExerciseLive.Details do
  use GymratWeb, :live_view

  alias Gymrat.Training.WorkoutExercises
  alias Gymrat.Training.Sets
  alias Gymrat.ExerciseFetcher
  import GymratWeb.MyComponents

  @colors [
    # blue
    %{border: "rgba(59, 130, 246, 0.7)", background: "rgba(59, 130, 246, 0.2)"},
    # purple
    %{border: "rgba(168, 85, 247, 0.7)", background: "rgba(168, 85, 247, 0.2)"},
    # red
    %{border: "rgba(239, 68, 68, 0.7)", background: "rgba(239, 68, 68, 0.2)"},
    # yellow
    %{border: "rgba(234, 179, 8, 0.7)", background: "rgba(234, 179, 8, 0.2)"},
    # green
    %{border: "rgba(34, 197, 94, 0.7)", background: "rgba(34, 197, 94, 0.2)"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}/workouts/#{@workout_id}"}
        title={@fetched_exercise["name"] || @workout_exercise.custom_name || "Unknown Exercise"}
      />

      <div class="collapse bg-primary text-primary-content border-primary border border-4">
        <input type="checkbox" class="peer" />
        <div class="collapse-title font-semibold">Details</div>
        <div class="collapse-content text-sm bg-primary text-primary-content peer-checked:bg-base-100/20 peer-checked:text-primary-content">
          <div class="flex flex-col gap-4">
            <%= if @workout_exercise.exercise_id do %>
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
                  <li
                    :for={instruction <- @fetched_exercise["instructions"] || []}
                    class="list-decimal"
                  >
                    {instruction}
                  </li>
                </ol>
              </div>
            <% else %>
              <img
                loading="lazy"
                src={@workout_exercise.custom_image_url}
                alt="Exercise Image"
                class="w-full h-56 object-cover"
              />
              <div>
                <strong>Description:</strong>
                <p>
                  {@workout_exercise.custom_description || "N/A"}
                </p>
              </div>
            <% end %>
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
        <ul class="order-first md:order-last">
          <%= for set <- @sets do %>
            <.list_item>
              <span>
                <strong>Weight:</strong> {set.weight} kg &nbsp; | &nbsp;
                <strong>Reps:</strong> {set.reps}
              </span>

              <.joined_action_group
                on_edit_navigate={
                  ~p"/plans/#{@plan_id}/workouts/#{@workout_id}/exercises/#{@workout_exercise.id}/sets/#{set.id}/edit"
                }
                on_delete="delete_set"
                resource_id={set.id}
                show_modal={@show_modal_set}
                resource_name="set"
              >
                <:modal_content>
                  <h2>Are you sure you want to delete this set?</h2>
                  <p>This action cannot be undone.</p>
                </:modal_content>
              </.joined_action_group>
            </.list_item>
          <% end %>

          <%= if Enum.empty?(@sets) do %>
            <p>
              No sets added yet.
              <a
                class="underline hover:text-secondary"
                href={
                  ~p"/plans/#{@plan_id}/workouts/#{@workout_id}/exercises/#{@workout_exercise.id}/sets/new"
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

      <div class="flex justify-end flex-wrap gap-2">
        <.button
          :if={@is_workout_exercise_from_user}
          phx-click="update_exercise"
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
          :if={@is_workout_exercise_from_user}
          class="btn btn-error btn-soft btn-square"
          phx-click="show_modal_exercise"
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

    case WorkoutExercises.get_workout_exercise(exercise_id) do
      {:ok, workout_exercise} ->
        sets =
          Sets.get_todays_exercise_with_sets(
            workout_exercise.exercise_id,
            workout_exercise.custom_name,
            user.id
          )

        fetched_exercise =
          if workout_exercise.exercise_id do
            {:ok, exercise} =
              ExerciseFetcher.fetch_exercise(workout_exercise.exercise_id)

            exercise
          else
            nil
          end

        {:ok,
         socket
         |> assign(:plan_id, plan_id)
         |> assign(:workout_id, workout_id)
         |> assign(:workout_exercise, workout_exercise)
         |> assign(:sets, sets)
         |> assign(:fetched_exercise, fetched_exercise)
         |> assign(:show_modal_set, false)
         |> assign(:show_modal_exercise, false)
         |> assign(:is_workout_exercise_from_user, is_workout_exercise_from_user)
         |> assign(:weight_chart_data, nil)
         |> assign(:reps_chart_data, nil)
         |> push_event("load_chart_data", %{})}

      {:error, _reason} ->
        {:error, :not_found}
    end
  end

  defp build_weight_chart_data(exercise_id, custom_name, user_id) do
    weight_by_day = Sets.get_sets_weight_by_day(exercise_id, custom_name, user_id)

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

    weight_raw_days =
      grouped_weight_by_day
      |> Map.keys()
      |> Enum.sort(fn a, b -> Date.compare(a, b) == :lt end)

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

  defp build_reps_chart_data(exercise_id, custom_name, user_id) do
    reps_by_day = Sets.get_sets_reps_by_day(exercise_id, custom_name, user_id)

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

    reps_raw_days =
      grouped_reps_by_day
      |> Map.keys()
      |> Enum.sort(fn a, b -> Date.compare(a, b) == :lt end)

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

    exercise_id =
      socket.assigns.workout_exercise.exercise_id

    custom_name = socket.assigns.workout_exercise.custom_name

    weight_chart_data = build_weight_chart_data(exercise_id, custom_name, user.id)
    reps_chart_data = build_reps_chart_data(exercise_id, custom_name, user.id)

    {:noreply,
     socket
     |> assign(:weight_chart_data, weight_chart_data)
     |> assign(:reps_chart_data, reps_chart_data)}
  end

  @impl true
  def handle_event("add_set", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to:
          ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{socket.assigns.workout_exercise.id}/sets/new"
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
    case WorkoutExercises.soft_delete_workout_exercise(socket.assigns.workout_exercise) do
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
  def handle_event("update_exercise", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to:
          ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{socket.assigns.workout_exercise.id}/edit"
      )
    }
  end

  @impl true
  def handle_event("delete_set", %{"id" => set_id}, socket) do
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
                  ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/#{socket.assigns.workout_exercise.id}"
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
end
