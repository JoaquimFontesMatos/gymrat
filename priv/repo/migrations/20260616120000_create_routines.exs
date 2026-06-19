defmodule Gymrat.Repo.Migrations.CreateRoutines do
  use Ecto.Migration

  def change do
    create table(:routines) do
      add :name, :string, null: false
      add :icon, :string
      add :deleted_at, :naive_datetime

      add :plan_id, references(:plans, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:routines, [:plan_id])

    create table(:routine_exercises) do
      add :exercise_id, :string
      add :custom_name, :string
      add :custom_description, :text
      add :custom_image_url, :text
      add :body_part, :string
      add :position, :integer, null: false, default: 0
      add :deleted_at, :naive_datetime

      add :routine_id, references(:routines, on_delete: :delete_all), null: false
    end

    create index(:routine_exercises, [:routine_id])
    create index(:routine_exercises, [:routine_id, :position])

    # Prevent duplicate provider exercise in the same routine (mirrors
    # workout_exercises; not filtered on deleted_at, the context revives).
    create unique_index(:routine_exercises, [:routine_id, :exercise_id])

    create table(:routine_sets) do
      add :position, :integer, null: false, default: 0
      add :reps_min, :integer, null: false
      add :reps_max, :integer
      add :rest_seconds, :integer
      add :deleted_at, :naive_datetime

      add :routine_exercise_id, references(:routine_exercises, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:routine_sets, [:routine_exercise_id])
    create index(:routine_sets, [:routine_exercise_id, :position])

    create table(:routine_set_logs) do
      add :reps, :integer, null: false
      add :weight, :float, null: false
      add :deleted_at, :naive_datetime

      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :routine_set_id, references(:routine_sets, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:routine_set_logs, [:routine_set_id])
    create index(:routine_set_logs, [:user_id])
  end
end
