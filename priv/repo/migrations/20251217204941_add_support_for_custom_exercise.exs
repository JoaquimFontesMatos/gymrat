defmodule Gymrat.Repo.Migrations.AddSupportForCustomExercise do
  use Ecto.Migration

  defmodule Gymrat.Repo.Migrations.AddSupportForCustomExercise do
    use Ecto.Migration

    def up do
      alter table(:workout_exercises) do
        add :custom_name, :string
        add :custom_description, :string
        add :custom_image_url, :string
        modify :exercise_id, :string, null: true
      end
    end

    def down do
      alter table(:workout_exercises) do
        remove :custom_name
        remove :custom_description
        remove :custom_image_url
        modify :exercise_id, :string, null: false
      end
    end
  end
end
