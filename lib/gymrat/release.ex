defmodule Gymrat.Release do
  @moduledoc """
  Production database tasks that run without Mix (e.g. migrations).

  Used both for automatic migration on boot (see `Gymrat.Application.start/2`)
  and for manual invocation, e.g. `mix ecto.migrate` locally or
  `Gymrat.Release.migrate/0` from an IEx/remote console.
  """
  @app :gymrat

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
