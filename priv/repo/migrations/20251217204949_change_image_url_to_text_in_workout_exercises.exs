defmodule Gymrat.Repo.Migrations.ChangeImageUrlToTextInWorkoutExercises do
  use Ecto.Migration

  def up do
    alter table(:workout_exercises) do
      modify :custom_image_url, :text
    end
  end

  def down do
    alter table(:workout_exercises) do
      remove :custom_image_url, :string
    end
  end
end
