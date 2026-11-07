defmodule Gymrat.TracingTest do
  use ExUnit.Case, async: true
  import Plug.Test
  require OpenTelemetry.Tracer

  test "removes token-bearing URL values from the current server span" do
    OpenTelemetry.Tracer.with_span "request", %{
      attributes: %{
        :"url.path" => "/users/log-in/private-token",
        :"url.query" => "code=private-code"
      }
    } do
      conn = conn(:get, "/")
      assert Gymrat.Tracing.call(conn, []) == conn

      span_id = OpenTelemetry.Tracer.current_span_ctx() |> :otel_span.span_id()
      [span] = :ets.lookup(:otel_span_table, span_id)
      attributes = inspect(span, limit: :infinity, printable_limit: :infinity)
      assert attributes =~ "[redacted]"
      refute attributes =~ "private-token"
      refute attributes =~ "private-code"
    end
  end
end
