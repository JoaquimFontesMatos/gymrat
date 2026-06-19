defmodule Gymrat.Routines.RoutineWeekday do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routine_weekdays" do
    field :weekday, :integer

    belongs_to :routine, Gymrat.Routines.Routine

    timestamps()
  end

  def changeset(rw, attrs) do
    rw
    |> cast(attrs, [:weekday, :routine_id])
    |> validate_required([:weekday, :routine_id])
  end
end
