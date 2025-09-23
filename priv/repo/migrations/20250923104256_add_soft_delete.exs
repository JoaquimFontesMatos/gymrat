defmodule Gymrat.Repo.Migrations.AddSoftDelete do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :deleted_at, :naive_datetime
    end

    alter table(:workouts) do
      add :deleted_at, :naive_datetime
    end

    alter table(:sets) do
      add :deleted_at, :naive_datetime
    end

    alter table(:plans) do
      add :deleted_at, :naive_datetime
    end

    alter table(:workout_exercises) do
      add :deleted_at, :naive_datetime
    end

    alter table(:user_plans) do
      add :deleted_at, :naive_datetime
    end
  end
end
