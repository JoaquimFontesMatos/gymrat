defmodule Gymrat.Repo.Migrations.ChangeWeekdayToInteger do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE workouts ALTER COLUMN weekday TYPE integer USING weekday::integer;")
  end

  def down do
    execute("ALTER TABLE workouts ALTER COLUMN weekday TYPE text;")
  end
end
