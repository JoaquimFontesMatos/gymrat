defmodule Gymrat.Accounts.UserWeight do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_weights" do
    field :weight, :float
    field :deleted_at, :naive_datetime
    belongs_to :user, Gymrat.Accounts.User

    timestamps()
  end

  def changeset(set, attrs) do
    set
    |> cast(attrs, [:weight, :user_id])
    |> validate_required([:weight, :user_id])
  end
end
