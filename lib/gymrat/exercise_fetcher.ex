defmodule Gymrat.ExerciseFetcher do
  @api_base "https://exercise-db-fitness-workout-gym.p.rapidapi.com"
  defp rapidapi_config do
    Application.fetch_env!(:gymrat, :rapidapi)
  end

  def filter_exercises(query) do
    url = "#{@api_base}/exercises/filter?#{query}"
    config = rapidapi_config()

    case Req.get(url,
           headers: [
             {"x-rapidapi-host", config[:host]},
             {"x-rapidapi-key", config[:key]}
           ]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: code}} ->
        {:error, "Unexpected status code: #{code}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_exercise(id) do
    url = "#{@api_base}/exercise/#{URI.encode(id)}"
    config = rapidapi_config()

    case Req.get(url,
           headers: [
             # Accessing the host and key with keyword list syntax
             {"x-rapidapi-host", config[:host]},
             {"x-rapidapi-key", config[:key]}
           ]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: code}} ->
        {:error, "Unexpected status code: #{code}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def filter_exercises_by_name(exercises, query) do
    query_down = String.downcase(query || "")

    filtered =
      exercises
      |> Enum.filter(fn %{"name" => name} ->
        name
        |> String.downcase()
        |> String.contains?(query_down)
      end)

    {:ok, filtered}
  end
end
