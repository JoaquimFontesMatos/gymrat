defmodule GymratWeb.PageControllerTest do
  use GymratWeb.ConnCase

  test "GET / redirects unauthenticated users to the log-in page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log-in"
  end
end
