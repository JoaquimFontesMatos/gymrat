defmodule Gymrat.ExerciseFetcher do
  @api_base "https://exercise-db-fitness-workout-gym.p.rapidapi.com"
  defp rapidapi_config do
    Application.fetch_env!(:gymrat, :rapidapi)
  end

  def fetch_all_exercises do
    url = "#{@api_base}/exercises"
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

  def search_exercise_by_name(query) do
    case fetch_all_exercises() do
      {:ok, %{"excercises_ids" => ids}} ->
        # Transform and keep track of original IDs
        transformed =
          ids
          |> Enum.map(fn id ->
            readable =
              id
              |> String.replace("_", " ")
              |> String.downcase()

            {id, readable}
          end)

        # Filter by search query
        matching_ids =
          transformed
          |> Enum.filter(fn {_id, readable} ->
            String.contains?(readable, String.downcase(query))
          end)
          |> Enum.map(fn {id, _readable} -> id end)

        {:ok, %{"excercises_ids" => matching_ids}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
