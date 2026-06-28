defmodule GymratWeb.Plugs.Health do
  @moduledoc """
  Dependency-free liveness/readiness endpoint for container orchestrators.

  Answers `GET /healthz` with `200 "ok"` without touching the session, router,
  or database, so Kubernetes probes stay cheap and don't depend on a LiveView
  mount. Wired as the first plug in `GymratWeb.Endpoint`.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{request_path: "/healthz"} = conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
