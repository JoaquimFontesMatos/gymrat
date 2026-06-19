defmodule GymratWeb.RoutineExerciseLive.Add do
  use GymratWeb, :live_view

  alias Gymrat.ExerciseFetcher
  alias Gymrat.ExerciseCache
  alias Gymrat.Training.RoutineExercises
  import GymratWeb.MyComponents

  @impl true
  def mount(%{"plan_id" => plan_id, "routine_id" => routine_id}, _session, socket) do
    plan_id = String.to_integer(plan_id)
    routine_id = String.to_integer(routine_id)

    initial_form = to_form(%{"name" => "", "muscle_group" => ""}, as: :search_form)

    socket =
      assign(socket,
        search_form: initial_form,
        plan_id: plan_id,
        routine_id: routine_id,
        exercises: [],
        added_ids: RoutineExercises.added_exercise_ids(routine_id),
        loading: true
      )

    {:ok, fetch_exercises(socket, nil, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header_with_back_navigate
        navigate={~p"/plans/#{@plan_id}/routines/#{@routine_id}"}
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

        <.button type="button" class="btn btn-primary" phx-click="add_custom_exercise">
          Add Custom
        </.button>
      </.form>

      <%= if @loading do %>
        <p class="mt-4 text-center">Loading exercises...</p>
      <% else %>
        <%= if @exercises && !Enum.empty?(@exercises) do %>
          <div class="gap-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 mt-8">
            <%= for exercise <- @exercises do %>
              <div class={[
                "group relative flex flex-col overflow-hidden rounded-2xl border bg-base-100 shadow-sm transition-all duration-200 hover:-translate-y-1 hover:shadow-xl",
                if(MapSet.member?(@added_ids, exercise["id"]),
                  do: "border-success/40 ring-1 ring-success/30",
                  else: "border-base-300"
                )
              ]}>
                <div class="relative h-36 overflow-hidden bg-base-200">
                  <img
                    loading="lazy"
                    src={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{exercise["id"] }/0.jpg"}
                    data-png={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{exercise["id"] }/0.png"}
                    data-webp={"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/#{exercise["id"] }/0.webp"}
                    alt={exercise["name"] || "Exercise"}
                    class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                    onerror="this.onerror=null; if(this.src.endsWith('.jpg')) {this.src=this.dataset.png;} else if(this.src.endsWith('.png')) {this.src=this.dataset.webp;} else {this.src='/images/default_exercise.jpg';}"
                  />
                  <span
                    :if={MapSet.member?(@added_ids, exercise["id"])}
                    class="absolute right-3 top-3 inline-flex items-center gap-1 rounded-full bg-success px-2.5 py-1 text-xs font-semibold text-success-content shadow"
                  >
                    <.icon name="hero-check" class="h-3.5 w-3.5" /> Added
                  </span>
                </div>

                <div class="flex flex-1 flex-col gap-3 p-4">
                  <h2 class="text-lg font-semibold capitalize leading-tight line-clamp-2">
                    {exercise["name"] || "N/A"}
                  </h2>

                  <div
                    :if={List.wrap(exercise["primaryMuscles"]) != []}
                    class="flex flex-wrap gap-1.5"
                  >
                    <span
                      :for={muscle <- List.wrap(exercise["primaryMuscles"])}
                      class="rounded-full bg-base-200 px-2.5 py-0.5 text-xs font-medium capitalize text-base-content/70"
                    >
                      {muscle}
                    </span>
                  </div>

                  <span
                    :if={exercise["level"]}
                    class={[
                      "inline-flex w-fit items-center rounded-full px-2.5 py-0.5 text-xs font-semibold capitalize",
                      level_badge_class(exercise["level"])
                    ]}
                  >
                    {exercise["level"]}
                  </span>

                  <div class="mt-auto pt-2">
                    <%= if MapSet.member?(@added_ids, exercise["id"]) do %>
                      <.button type="button" class="btn btn-disabled w-full" disabled>
                        <.icon name="hero-check" class="h-4 w-4" /> Added
                      </.button>
                    <% else %>
                      <.button
                        type="button"
                        class="btn btn-primary w-full"
                        phx-click="add_exercise"
                        phx-value-exercise-id={exercise["id"]}
                        phx-value-body-part={List.first(List.wrap(exercise["primaryMuscles"]))}
                      >
                        <.icon name="hero-plus" class="h-4 w-4" /> Add Exercise
                      </.button>
                    <% end %>
                  </div>
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

  def handle_event(
        "search_validate",
        %{"search_form" => %{"name" => name, "muscle_group" => muscle_group}},
        socket
      ) do
    form =
      to_form(%{"name" => name || "", "muscle_group" => muscle_group || ""}, as: :search_form)

    {:noreply, assign(socket, search_form: form)}
  end

  def handle_event("add_exercise", %{"exercise-id" => exercise_id} = params, socket) do
    routine_exercise_params = %{
      "routine_id" => socket.assigns.routine_id,
      "exercise_id" => exercise_id,
      "body_part" => params["body-part"]
    }

    case RoutineExercises.create_routine_exercise(routine_exercise_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "The exercise was added!")
         |> push_navigate(
           to: ~p"/plans/#{socket.assigns.plan_id}/routines/#{socket.assigns.routine_id}"
         )}

      {:error, :already_added} ->
        {:noreply, put_flash(socket, :info, "That exercise is already in this routine.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Couldn't add the exercise. Please try again.")}
    end
  end

  def handle_event("add_custom_exercise", _payload, socket) do
    {:noreply,
     push_navigate(socket,
       to:
         ~p"/plans/#{socket.assigns.plan_id}/routines/#{socket.assigns.routine_id}/exercises/new/custom"
     )}
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

  defp level_badge_class("beginner"), do: "bg-green-200 text-green-800"
  defp level_badge_class("intermediate"), do: "bg-yellow-200 text-yellow-800"
  defp level_badge_class("expert"), do: "bg-red-200 text-red-800"
  defp level_badge_class(_), do: "bg-gray-200 text-gray-600"

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
