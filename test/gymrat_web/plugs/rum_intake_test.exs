defmodule GymratWeb.Plugs.RumIntakeTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias GymratWeb.Plugs.RumIntake

  setup do
    previous_token = Application.get_env(:gymrat, :rum_token)
    previous_options = Application.get_env(:gymrat, :rum_request_options)
    Application.put_env(:gymrat, :rum_token, "test-rum-token")
    Application.put_env(:gymrat, :rum_request_options, plug: {Req.Test, __MODULE__})

    on_exit(fn ->
      restore_env(:rum_token, previous_token)
      restore_env(:rum_request_options, previous_options)
    end)
  end

  test "forwards RUM and replay batches with the server token and no browser cookies" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path in ["/rum/v1/default/rum", "/rum/v1/default/replay"]
      assert conn.query_params["o2-api-key"] == "test-rum-token"
      assert conn.query_params["o2source"] == "browser"
      assert Plug.Conn.get_req_header(conn, "cookie") == []
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert body == "browser-batch"
      Plug.Conn.send_resp(conn, 200, "")
    end)

    for kind <- ["rum", "replay"] do
      conn =
        conn(:post, "/rum/v1/default/#{kind}?o2-api-key=public&o2source=browser", "browser-batch")
        |> Plug.Conn.put_req_header("content-type", "text/plain")
        |> Plug.Conn.put_req_header("cookie", "session=private")
        |> RumIntake.call([])

      assert conn.status == 204
      assert conn.halted
    end
  end

  test "does not expose an intake when no token is configured" do
    Application.delete_env(:gymrat, :rum_token)
    conn = conn(:post, "/rum/v1/default/rum", "batch") |> RumIntake.call([])
    assert conn.status == 404
  end

  test "does not proxy arbitrary paths or methods" do
    for {method, path} <- [{:post, "/rum/v1/default/logs"}, {:get, "/rum/v1/default/rum"}] do
      conn = conn(method, path) |> RumIntake.call([])
      refute conn.halted
    end
  end

  test "rejects oversized request bodies" do
    conn = conn(:post, "/rum/v1/default/replay", String.duplicate("x", 2_000_001))
    assert RumIntake.call(conn, []).status == 413
  end

  test "does not follow upstream redirects" do
    Req.Test.stub(__MODULE__, fn conn ->
      conn
      |> Plug.Conn.put_resp_header("location", "https://example.invalid/intake")
      |> Plug.Conn.send_resp(302, "")
    end)

    conn = conn(:post, "/rum/v1/default/rum", "batch") |> RumIntake.call([])
    assert conn.status == 502
  end

  defp restore_env(key, nil), do: Application.delete_env(:gymrat, key)
  defp restore_env(key, value), do: Application.put_env(:gymrat, key, value)
end
