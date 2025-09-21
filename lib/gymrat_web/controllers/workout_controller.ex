defmodule GymratWeb.WorkoutController do
  use GymratWeb, :controller
  alias Gymrat.Training

  def index(conn, _params) do
    workouts = Training.list_workouts()
    json(conn, workouts)
  end

  def create(conn, %{"workout" => workout_params}) do
    case Training.create_workout(workout_params) do
      {:ok, workout} ->
        json(conn, workout)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset})
    end
  end
end
