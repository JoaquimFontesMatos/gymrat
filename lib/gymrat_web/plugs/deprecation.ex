defmodule GymratWeb.Plugs.Deprecation do
  @moduledoc """
  Deprecation notice for the retired Gigalixir host.

  When the `DEPRECATED_REDIRECT_URL` env var is set, every request (except
  `GET /healthz`, which is short-circuited earlier by `GymratWeb.Plugs.Health`)
  is answered with a small dependency-free "this site has moved" page linking to
  the new host. When the var is unset — as on the live k8s deployment — this plug
  is completely inert and passes the connection straight through, so it can never
  affect the new site. Wired right after the health plug in `GymratWeb.Endpoint`.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case System.get_env("DEPRECATED_REDIRECT_URL") do
      url when is_binary(url) and url != "" ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, page(url))
        |> halt()

      _ ->
        conn
    end
  end

  defp page(url) do
    safe_url = url |> to_string() |> Plug.HTML.html_escape()

    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="robots" content="noindex" />
        <title>gymrat has moved</title>
        <style>
          :root { color-scheme: light dark; }
          body {
            margin: 0; min-height: 100vh; display: flex; align-items: center;
            justify-content: center; font-family: system-ui, -apple-system, sans-serif;
            background: #0f172a; color: #e2e8f0; text-align: center; padding: 1.5rem;
          }
          .card {
            max-width: 28rem; padding: 2.5rem 2rem; border-radius: 1rem;
            background: #1e293b; box-shadow: 0 10px 30px rgba(0,0,0,.35);
          }
          h1 { margin: 0 0 .5rem; font-size: 1.5rem; }
          p { margin: 0 0 1.75rem; color: #94a3b8; line-height: 1.5; }
          a.btn {
            display: inline-block; padding: .75rem 1.5rem; border-radius: .5rem;
            background: #6366f1; color: #fff; text-decoration: none; font-weight: 600;
          }
          a.btn:hover { background: #4f46e5; }
        </style>
      </head>
      <body>
        <main class="card">
          <h1>This site has moved</h1>
          <p>gymrat now lives at a new home. This address is no longer maintained.</p>
          <a class="btn" href="#{safe_url}">Go to the new gymrat &rarr;</a>
        </main>
      </body>
    </html>
    """
  end
end
