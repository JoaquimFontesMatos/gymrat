defmodule GymratWeb.ExportController do
  use GymratWeb, :controller

  alias Gymrat.Training.{Sets, UserWeights}

  @doc "Downloads the current user's logged sets as CSV."
  def sets(conn, _params) do
    rows =
      conn.assigns.current_scope.user.id
      |> Sets.list_sets_for_export()
      |> Enum.map(fn s ->
        [NaiveDateTime.to_date(s.inserted_at), s.exercise, s.reps, s.weight]
      end)

    send_csv(conn, "gymrat_sets.csv", ["date", "exercise", "reps", "weight"], rows)
  end

  @doc "Downloads the current user's body-weight log as CSV."
  def weights(conn, _params) do
    rows =
      conn.assigns.current_scope.user.id
      |> UserWeights.get_weights_by_insertdate()
      |> Enum.map(fn w -> [NaiveDateTime.to_date(w.inserted_at), w.weight] end)

    send_csv(conn, "gymrat_weights.csv", ["date", "weight"], rows)
  end

  defp send_csv(conn, filename, headers, rows) do
    body =
      [headers | rows]
      |> Enum.map_join("\r\n", fn cols -> Enum.map_join(cols, ",", &csv_field/1) end)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> send_resp(200, body)
  end

  defp csv_field(value) do
    str = to_string(value)

    if String.contains?(str, [",", "\"", "\n", "\r"]) do
      ~s("#{String.replace(str, "\"", "\"\"")}")
    else
      str
    end
  end
end
