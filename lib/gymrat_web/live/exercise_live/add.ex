defmodule GymratWeb.ExerciseLive.Add do
  use GymratWeb, :live_view

  alias Gymrat.ExerciseFetcher
  alias Gymrat.Training.WorkoutExercises

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
        loading: true
      )

    {:ok, fetch_exercises(socket, nil, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl px-4 py-8">
        <h1 class="text-3xl font-bold mb-6">Exercises Database</h1>
        <.form for={@search_form} id="search_form" phx-submit="search" phx-change="search_validate">
          <.input
            field={@search_form[:name]}
            type="search"
            label="Search Exercises"
            placeholder="e.g., biceps, triceps, bench press"
            phx-debounce="300"
          />
          <.input
            field={@search_form[:muscle_group]}
            type="select"
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
          <.button type="submit" class="btn btn-primary ml-2">Search</.button>
        </.form>

        <%= if @loading do %>
          <p class="text-center mt-4">Loading exercises...</p>
        <% else %>
          <%= if @exercises && !Enum.empty?(@exercises) do %>
            <div class="mt-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for exercise <- @exercises do %>
                <div class="border rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow flex flex-col items-between">
                  <div
                    phx-click="toggle_exercise_details"
                    phx-value-exercise-id={exercise["id"]}
                    class="cursor-pointer grow pb-4"
                  >
                    <h2 class="text-xl font-semibold mb-2">
                      {exercise["name"] || "N/A"}
                    </h2>

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
                    <.button
                      type="button"
                      class="btn btn-primary"
                      phx-click="add_exercise"
                      phx-value-exercise-id={exercise["id"]}
                    >
                      Add Exercise
                    </.button>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <p class="text-center mt-4 text-gray-700">No exercises found.</p>
          <% end %>
        <% end %>
      </div>
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
  def handle_event("add_exercise", %{"exercise-id" => exercise_id}, socket) do
    workout_exercises_params = %{
      "workout_id" => socket.assigns.workout_id,
      "exercise_id" => exercise_id
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

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp fetch_exercises(socket, name, muscle_group) do
    name = String.trim(name || "")
    mg = muscle_group || ""

    params =
      cond do
        mg != "" ->
          %{"muscle" => mg}

        true ->
          %{}
      end

    query_string = URI.encode_query(params)

    socket = assign(socket, loading: true)

    case ExerciseFetcher.filter_exercises(query_string) do
      {:ok, exercises} when is_list(exercises) ->
        exercises =
          if name != "" do
            case ExerciseFetcher.filter_exercises_by_name(exercises, name) do
              {:ok, filtered} -> filtered
              {:error, _} -> []
            end
          else
            exercises
          end

        assign(socket,
          exercises: exercises,
          loading: false,
          search_form: to_form(%{"name" => name, "muscle_group" => mg}, as: :search_form)
        )

      {:ok, unexpected_body} ->
        socket
        |> put_flash(
          :error,
          "Unexpected API data format. Expected a list: #{inspect(unexpected_body)}"
        )
        |> assign(loading: false, exercises: [])

      {:error, reason} ->
        socket
        |> put_flash(:error, "Failed to fetch exercises: #{inspect(reason)}")
        |> assign(
          exercises: [],
          loading: false,
          search_form: to_form(%{"name" => name, "muscle_group" => mg}, as: :search_form)
        )
    end
  end
end
