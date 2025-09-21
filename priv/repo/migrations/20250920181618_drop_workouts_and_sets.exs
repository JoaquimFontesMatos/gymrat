defmodule Gymrat.Repo.Migrations.DropWorkoutsAndSets do
  use Ecto.Migration

  def change do
    drop table(:sets)
    drop table(:workouts)
  end
end
