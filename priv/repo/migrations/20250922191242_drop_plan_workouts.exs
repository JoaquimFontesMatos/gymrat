defmodule Gymrat.Repo.Migrations.DropPlanWorkouts do
  use Ecto.Migration

  def change do
    drop table(:plan_workouts)

    alter table(:workouts) do
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
      remove :creator_id
    end
  end
end
