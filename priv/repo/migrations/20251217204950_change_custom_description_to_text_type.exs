defmodule Gymrat.Repo.Migrations.ChangeCustomDescriptionToTextType do
  use Ecto.Migration

  def up do
    alter table(:workout_exercises) do
      modify :custom_description, :text
    end
  end

  def down do
    alter table(:workout_exercises) do
      remove :custom_description, :string
    end
  end
end
