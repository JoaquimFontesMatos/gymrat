defmodule GymratWeb.ExerciseLive.Add do
  use GymratWeb, :live_view

  alias Gymrat.ExerciseFetcher
  alias Gymrat.Training

  @impl true
  def mount(%{"plan_id" => plan_id, "workout_id" => workout_id}, _session, socket) do
    plan_id = String.to_integer(plan_id)
    workout_id = String.to_integer(workout_id)

    # Initialize an empty form for the search_form.
    # This ensures @search_form is always present for the first render.
    initial_form = to_form(%{"query" => ""}, as: :search_form)

    # Assign initial form, then fetch exercises.
    # The `fetch_exercises` helper should also ensure `search_form` is assigned.
    socket = assign(socket, search_form: initial_form, plan_id: plan_id, workout_id: workout_id)

    {:ok, fetch_exercises(socket, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl px-4 py-8">
        <h1 class="text-3xl font-bold mb-6">Exercises Database</h1>
        <.form for={@search_form} id="search_form" phx-submit="search" phx-change="search_validate">
          <.input
            field={@search_form[:query]}
            type="search"
            label="Search Exercises"
            placeholder="e.g., biceps, triceps, bench press"
            phx-debounce="300"
          />
          <.button type="submit" class="btn btn-primary ml-2">Search</.button>
        </.form>

        <%= if @loading do %>
          <p class="text-center mt-4">Loading exercises...</p>
        <% else %>
          <%= if @exercises_ids && !Enum.empty?(@exercises_ids) do %>
            <div class="mt-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for exercise_id <- @exercises_ids do %>
                <div class="border rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow">
                  <h2 class="text-xl font-semibold mb-2">
                    {exercise_id
                    |> String.replace("_", " ")
                    |> String.capitalize()}
                  </h2>
                  <p class="text-gray-600">ID: {exercise_id}</p>
                  <div class="mt-4"></div>
                  <div class="flex justify-end">
                    <.button
                      type="button"
                      class="btn btn-primary"
                      phx-click="add_exercise"
                      phx-value-exercise-id={exercise_id}
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
  def handle_event("search", %{"search_form" => %{"query" => query}}, socket) do
    {:noreply, fetch_exercises(socket, query)}
  end

  @impl true
  def handle_event("search_validate", %{"search_form" => %{"query" => query}}, socket) do
    # When validating, just update the form's representation in the socket
    # without re-fetching all data, if that's your debounce strategy.
    # The `fetch_exercises` helper already handles assigning the form
    # correctly, so we can reuse that for simplicity or just assign the form.
    # Ensure form data is kept
    form = to_form(%{"query" => query || ""}, as: :search_form)
    {:noreply, assign(socket, search_form: form)}
  end

  @impl true
  def handle_event("add_exercise", %{"exercise-id" => exercise_id}, socket) do
    workout_exercises_params = %{
      "workout_id" => socket.assigns.workout_id,
      "exercise_id" => exercise_id
    }

    case Training.create_workout_exercise(workout_exercises_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The exercise was added!"
          )
          |> push_navigate(
            to: ~p"/plans/#{socket.assigns.plan_id}/workouts/#{socket.assigns.workout_id}"
          )
        }

      {:error, _} ->
        {:noreply}
    end
  end

  defp fetch_exercises(socket, query) do
    socket = assign(socket, loading: true)

    # Prepare the query string, defaulting to empty if nil
    actual_query = query || ""

    case (if actual_query != "" do
            ExerciseFetcher.search_exercise_by_name(actual_query)
          else
            ExerciseFetcher.fetch_all_exercises()
          end) do
      {:ok, %{"excercises_ids" => ids}} ->
        assign(socket,
          exercises_ids: ids,
          loading: false,
          search_form: to_form(%{"query" => actual_query}, as: :search_form)
        )

      {:error, reason} ->
        socket
        |> put_flash(:error, "Failed to fetch exercises: #{inspect(reason)}")
        |> assign(
          exercises_ids: [],
          loading: false,
          search_form: to_form(%{"query" => actual_query}, as: :search_form)
        )
    end
  end
end
