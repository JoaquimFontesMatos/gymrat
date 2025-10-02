defmodule Gymrat.Repo.Migrations.AddPlanShareToken do
  use Ecto.Migration

  def change do
    alter table(:plans) do
      add :share_token, :string
    end

    create unique_index(:plans, [:share_token])
  end
end
