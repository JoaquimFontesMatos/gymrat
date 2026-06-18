defmodule Gymrat.Repo.Migrations.CreateRoutineWeekdays do
  use Ecto.Migration

  def change do
    create table(:routine_weekdays) do
      add :weekday, :integer, null: false

      add :routine_id, references(:routines, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:routine_weekdays, [:routine_id])
    create unique_index(:routine_weekdays, [:routine_id, :weekday])
  end
end
