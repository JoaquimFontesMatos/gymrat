defmodule GymratWeb.PageControllerTest do
  use GymratWeb.ConnCase

  test "GET / redirects unauthenticated users to the log-in page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log-in"
    [policy] = get_resp_header(conn, "content-security-policy")
    assert policy =~ "script-src 'self'"
    assert policy =~ "img-src 'self' data: blob: https:"
    refute policy =~ "script-src 'unsafe-inline'"
  end
end
