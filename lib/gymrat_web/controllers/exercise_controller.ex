defmodule GymratWeb.ExerciseController do
  use GymratWeb, :controller
  alias Gymrat.ExerciseFetcher

  # GET /api/exercises?search=optional_query
  def index(conn, params) do
    search_query = Map.get(params, "search")

    result =
      if search_query do
        # If a search query is present, use the search function
        ExerciseFetcher.search_exercise_by_name(search_query)
      else
        # Otherwise, just return all exercise IDs
        ExerciseFetcher.fetch_all_exercises()
      end

    case result do
      {:ok, exercises} ->
        json(conn, exercises)

      {:error, _reason} ->
        send_resp(conn, 503, "API unavailable")
    end
  end

  # GET /api/exercises/:id
  def show(conn, %{"id" => id}) do
    case ExerciseFetcher.fetch_exercise(id) do
      {:ok, exercise} -> json(conn, exercise)
      {:error, _} -> send_resp(conn, 404, "Exercise not found")
    end
  end
end
