defmodule Gymrat.Repo.Migrations.CreateUserWorkoutWorkoutExercisesSets do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :color, :string

      timestamps()
    end

    create unique_index(:users, [:name])

    create table(:plans) do
      add :name, :string

      add :creator_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create table(:user_plans) do
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    # Prevent duplicate entries like user_id=1, plan_id=1 twice
    create unique_index(:user_plans, [:user_id, :plan_id])

    create table(:workouts) do
      add :name, :string

      add :creator_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:workouts, [:creator_id])

    create table(:plan_workouts) do
      add :workout_id, references(:workouts, on_delete: :delete_all), null: false
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
    end

    # Prevent duplicate workout-plan pairs
    create unique_index(:plan_workouts, [:plan_id, :workout_id])

    create table(:workout_exercises) do
      add :exercise_id, :string, null: false
      add :workout_id, references(:workouts, on_delete: :delete_all), null: false
    end

    # Prevent duplicate exercise in same workout
    create unique_index(:workout_exercises, [:workout_id, :exercise_id])

    create table(:sets) do
      add :reps, :integer
      add :weight, :float

      add :workout_exercises_id, references(:workout_exercises, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:sets, [:workout_exercises_id])
  end
end
