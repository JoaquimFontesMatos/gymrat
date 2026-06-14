defmodule GymratWeb.ExportControllerTest do
  use GymratWeb.ConnCase, async: true

  import Gymrat.TrainingFixtures

  alias Gymrat.Training.UserWeights

  setup :register_and_log_in_user

  describe "GET /export/sets.csv" do
    test "returns the user's sets as a CSV download", %{conn: conn, user: user} do
      we = workout_exercise_chain_fixture(user)
      set_fixture(user, we, %{reps: 8, weight: 60.0})

      conn = get(conn, ~p"/export/sets.csv")

      assert response_content_type(conn, :csv)

      assert get_resp_header(conn, "content-disposition") == [
               ~s(attachment; filename="gymrat_sets.csv")
             ]

      body = response(conn, 200)
      assert body =~ "date,exercise,reps,weight"
      assert body =~ "0001,8,60.0"
    end
  end

  describe "GET /export/weights.csv" do
    test "returns the user's body weights as a CSV download", %{conn: conn, user: user} do
      {:ok, _} = UserWeights.create_user_weight(%{weight: 81.5, user_id: user.id})

      conn = get(conn, ~p"/export/weights.csv")

      assert response_content_type(conn, :csv)
      body = response(conn, 200)
      assert body =~ "date,weight"
      assert body =~ "81.5"
    end
  end

  test "requires authentication" do
    conn = get(Phoenix.ConnTest.build_conn(), ~p"/export/sets.csv")
    assert redirected_to(conn) == ~p"/users/log-in"
  end
end
