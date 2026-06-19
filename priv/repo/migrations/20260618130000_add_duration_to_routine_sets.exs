defmodule Gymrat.Repo.Migrations.AddDurationToRoutineSets do
  use Ecto.Migration

  def change do
    # A planned set is now either reps-based or time-based, so reps is no longer
    # mandatory and a duration column is added on both the plan and the log.
    alter table(:routine_sets) do
      add :duration_seconds, :integer
      modify :reps_min, :integer, null: true, from: {:integer, null: false}
    end

    alter table(:routine_set_logs) do
      add :duration_seconds, :integer
      modify :reps, :integer, null: true, from: {:integer, null: false}
    end
  end
end
