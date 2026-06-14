defmodule GymratWeb.ExerciseLive.Add do
  use GymratWeb, :live_view

  alias Gymrat.ExerciseFetcher
  alias Gymrat.ExerciseCache
  alias Gymrat.Training.WorkoutExercises
  import GymratWeb.MyComponents

  @impl true
  def mount(%{"plan_id" => plan_id, "workout_id" => workout_id}, _session, socket) do
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)

    initial_form = to_form(%{"name" => "", "muscle_group" => ""}, as: :search_form)

    socket =
      assign(socket,
        search_form: initial_form,
        plan_id: plan_id,
        workout_id: workout_id,
        exercises: [],
        added_ids: WorkoutExercises.added_exercise_ids(workout_id),
        loading: true
      )

    {:ok, fetch_exercises(socket, nil, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}/workouts/#{@workout_id}"}
        title="Exercises Database"
      />

      <.form for={@search_form} id="search_form" phx-submit="search" phx-change="search_validate">
        <div class="join">
          <.input
            field={@search_form[:name]}
            type="search"
            class="input join-item"
            label="Search Exercise"
            placeholder="e.g., biceps, triceps, bench press"
            phx-debounce="300"
          />
          <.input
            field={@search_form[:muscle_group]}
            type="select"
            class="select join-item"
            label="Muscle Group"
            options={[
              {"All", ""},
              {"Quadriceps", "quadriceps"},
              {"Shoulders", "shoulders"},
              {"Abdominals", "abdominals"},
              {"Chest", "chest"},
              {"Hamstrings", "hamstrings"},
              {"Triceps", "triceps"},
              {"Biceps", "biceps"},
              {"Lats", "lats"},
              {"Middle Back", "middle_back"},
              {"Forearms", "forearms"},
              {"Glutes", "glutes"},
              {"Traps", "traps"},
              {"Adductors", "adductors"},
              {"Abductors", "abductors"},
              {"Neck", "neck"}
            ]}
          />
        </div>

        <.button type="submit" class="btn btn-primary">Search</.button>

        <.button
          type="button"
          class="btn btn-primary"
          phx-click="add_custom_exercise"
        >
          Add Custom
        </.button>
      </.form>

      <%= if @loading do %>
        <p class="mt-4 text-center">Loading exercises...</p>
      <% else %>
        <%= if @exercises && !Enum.empty?(@exercises) do %>
          <div class="gap-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 mt-8">
            <%= for exercise <- @exercises do %>
              <div class="relative flex flex-col items-between bg-base-100 shadow-sm hover:shadow-md p-4 border rounded-lg transition-shadow">
                <div>
                  <div class="flex justify-between items-center gap-2 mb-2 pr-15">
                    <h2 class="font-semibold text-xl">
                      {exercise["name"] || "N/A"}
                    </h2>
                    <span
                      :if={MapSet.member?(@added_ids, exercise["id"])}
                      class="top-5 right-0 absolute gap-1 badge badge-success shrink-0"
                    >
                      <.icon name="hero-check" class="w-4 h-4" />
                    </span>
                  </div>

                  <div class="mt-2 p-2 rounded">
                    <img
                      loading="lazy"
                      src={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{exercise["id"] }/0.jpg"}
                      data-png={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{exercise["id"] }/0.png"}
                      data-webp={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{exercise["id"] }/0.webp"}
                      alt="Exercise Image"
                      class="w-full h-24 object-cover"
                      onerror="this.onerror=null; if(this.src.endsWith('.jpg')) {this.src=this.dataset.png;} else if(this.src.endsWith('.png')) {this.src=this.dataset.webp;} else {this.src='/images/default_exercise.jpg';}"
                    />
                    <p>
                      <strong>Primary Muscles:</strong>
                      {Enum.join(List.wrap(exercise["primaryMuscles"] || []), ", ")}
                    </p>
                    <p><strong>Level:</strong> {exercise["level"] || "N/A"}</p>
                  </div>
                </div>

                <div class="m-auto">
                  <%= if MapSet.member?(@added_ids, exercise["id"]) do %>
                    <.button type="button" class="btn btn-disabled" disabled>
                      Added
                    </.button>
                  <% else %>
                    <.button
                      type="button"
                      class="btn btn-primary"
                      phx-click="add_exercise"
                      phx-value-exercise-id={exercise["id"]}
                      phx-value-body-part={List.first(List.wrap(exercise["primaryMuscles"]))}
                    >
                      Add Exercise
                    </.button>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="mt-4 text-gray-700 text-center">No exercises found.</p>
        <% end %>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event(
        "search",
        %{"search_form" => %{"name" => name, "muscle_group" => muscle_group}},
        socket
      ) do
    {:noreply, fetch_exercises(socket, name, muscle_group)}
  end

  @impl true
  def handle_event(
        "search_validate",
        %{"search_form" => %{"name" => name, "muscle_group" => muscle_group}},
        socket
      ) do
    form =
      to_form(%{"name" => name || "", "muscle_group" => muscle_group || ""}, as: :search_form)

    {:noreply, assign(socket, search_form: form)}
  end

  @impl true
  def handle_event("add_exercise", %{"exercise-id" => exercise_id} = params, socket) do
    workout_exercises_params = %{
      "workout_id" => socket.assigns.workout_id,
      "exercise_id" => exercise_id,
      "body_part" => params["body-part"]
    }

    case WorkoutExercises.create_workout_exercise(workout_exercises_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "The exercise was added!")
          |> push_navigate(
            to: ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}"
          )
        }

      {:error, :already_added} ->
        {:noreply, put_flash(socket, :info, "That exercise is already in this workout.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Couldn't add the exercise. Please try again.")}
    end
  end

  @impl true
  def handle_event("add_custom_exercise", _payload, socket) do
    {
      :noreply,
      socket
      # Navigate via LiveView push_navigate
      |> push_navigate(
        to:
          ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}/exercises/new/custom"
      )
    }
  end

  @impl true
  def handle_async(:search, {:ok, {:ok, exercises}}, socket) do
    {:noreply, assign(socket, exercises: exercises, loading: false)}
  end

  def handle_async(:search, {:ok, {:unexpected, body}}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Unexpected API data format. Expected a list: #{inspect(body)}")
     |> assign(exercises: [], loading: false)}
  end

  def handle_async(:search, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Failed to fetch exercises: #{inspect(reason)}")
     |> assign(exercises: [], loading: false)}
  end

  def handle_async(:search, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Failed to fetch exercises: #{inspect(reason)}")
     |> assign(exercises: [], loading: false)}
  end

  # Sets the loading state immediately and runs the (cached) API lookup off the
  # critical path so search/mount never blocks on the external API. Results land
  # in handle_async/3 above.
  defp fetch_exercises(socket, name, muscle_group) do
    name = String.trim(name || "")
    mg = muscle_group || ""
    query_string = URI.encode_query(if mg != "", do: %{"muscle" => mg}, else: %{})

    socket =
      assign(socket,
        loading: true,
        search_form: to_form(%{"name" => name, "muscle_group" => mg}, as: :search_form)
      )

    if connected?(socket) do
      start_async(socket, :search, fn -> search_exercises(query_string, name) end)
    else
      socket
    end
  end

  defp search_exercises(query_string, name) do
    case ExerciseCache.get_filtered(query_string) do
      {:ok, exercises} when is_list(exercises) ->
        if name != "" do
          case ExerciseFetcher.filter_exercises_by_name(exercises, name) do
            {:ok, filtered} -> {:ok, filtered}
          end
        else
          {:ok, exercises}
        end

      {:ok, unexpected_body} ->
        {:unexpected, unexpected_body}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
