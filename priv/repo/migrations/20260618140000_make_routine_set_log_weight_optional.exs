defmodule Gymrat.Repo.Migrations.MakeRoutineSetLogWeightOptional do
  use Ecto.Migration

  def change do
    # Timed holds may be bodyweight, so weight is no longer mandatory on a log
    # (it stays required for reps-based logs via the changeset).
    alter table(:routine_set_logs) do
      modify :weight, :float, null: true, from: {:float, null: false}
    end
  end
end
