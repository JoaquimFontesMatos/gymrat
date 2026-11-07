defmodule GymratWeb.Plugs.RumIntake do
  @moduledoc """
  Forwards only browser RUM and replay batches to the private OpenObserve service.
  The RUM token stays on the server; no browser cookies or arbitrary headers are forwarded.
  """
  import Plug.Conn

  @max_body_bytes 2_000_000
  @max_query_bytes 4_096
  @upstream "http://openobserve.openobserve.svc.cluster.local:5080"

  def init(opts), do: opts

  def call(%{path_info: ["rum", "v1", "default", kind], method: "POST"} = conn, _opts)
      when kind in ["rum", "replay"] do
    case Application.get_env(:gymrat, :rum_token) do
      token when is_binary(token) and token != "" -> forward(conn, kind, token)
      _ -> conn |> send_resp(404, "") |> halt()
    end
  end

  def call(conn, _opts), do: conn

  defp forward(conn, _kind, _token) when byte_size(conn.query_string) > @max_query_bytes do
    conn |> send_resp(414, "") |> halt()
  end

  defp forward(conn, kind, token) do
    case read_body(conn, length: @max_body_bytes, read_length: 64_000, read_timeout: 5_000) do
      {:ok, body, conn} -> send_batch(conn, kind, token, body)
      {:more, _body, conn} -> conn |> send_resp(413, "") |> halt()
      {:error, _reason} -> conn |> send_resp(400, "") |> halt()
    end
  end

  defp send_batch(conn, kind, token, body) do
    query =
      conn.query_string
      |> URI.decode_query()
      |> Map.put("o2-api-key", token)
      |> URI.encode_query()

    content_type = get_req_header(conn, "content-type") |> List.first("application/octet-stream")

    options = [
      body: body,
      headers: [{"content-type", content_type}],
      retry: false,
      redirect: false,
      receive_timeout: 5_000
    ]

    options = Keyword.merge(options, Application.get_env(:gymrat, :rum_request_options, []))

    upstream = Application.get_env(:gymrat, :rum_upstream) || @upstream

    case Req.post("#{upstream}/rum/v1/default/#{kind}?#{query}", options) do
      {:ok, %Req.Response{status: status}} when status in 200..299 ->
        conn |> put_resp_header("cache-control", "no-store") |> send_resp(204, "") |> halt()

      _ ->
        conn |> put_resp_header("cache-control", "no-store") |> send_resp(502, "") |> halt()
    end
  end
end
