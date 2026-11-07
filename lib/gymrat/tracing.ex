defmodule Gymrat.Tracing do
  @moduledoc false

  def setup do
    OpentelemetryBandit.setup()
    OpentelemetryPhoenix.setup(adapter: :bandit)
    OpentelemetryEcto.setup([:gymrat, :repo])
  end

  def init(opts), do: opts

  # Bandit starts its span before the endpoint runs and records raw URLs.
  # Phoenix adds the parameterized route separately when a route matches.
  def call(conn, _opts) do
    OpenTelemetry.Tracer.set_attributes(%{
      :"url.path" => "[redacted]",
      :"url.query" => "[redacted]"
    })

    conn
  end
end
