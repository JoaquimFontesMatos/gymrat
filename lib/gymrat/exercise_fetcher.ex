defmodule Gymrat.ExerciseFetcher do
  @api_base "https://exercise-db-fitness-workout-gym.p.rapidapi.com"

  # The upstream ExerciseDB is flaky and frequently returns 504/500. A warm cache
  # hides this, but right after a restart the empty cache forces every page to hit
  # the API, so we retry transient failures more aggressively than Req's default of
  # 3 to give a cold start a better chance of populating the cache.
  @max_retries 6
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
           ],
           retry: :transient,
           max_retries: @max_retries
         ) do
      # An empty list almost always means a transient upstream glitch rather than
      # a genuine "no exercises" result, so we treat it as an error: it must not
      # be cached, and the next request retries the API.
      {:ok, %Req.Response{status: 200, body: body}} when is_list(body) and body != [] ->
        {:ok, body}

      {:ok, %Req.Response{status: 200, body: _body}} ->
        {:error, "Empty or invalid response body"}

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
           ],
           retry: :transient,
           max_retries: @max_retries
         ) do
      # The API answers unknown ids (and transient glitches) with 200 + an empty
      # body. Caching that would poison the cache permanently, so reject it as an
      # error: the cache only stores {:ok, _}, so the next request retries the API.
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) and map_size(body) > 0 ->
        {:ok, body}

      {:ok, %Req.Response{status: 200, body: _body}} ->
        {:error, "Empty or invalid response body"}

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
