defmodule Gymrat.Training.UserWeights do
  import Ecto.Query
  import Ecto.Changeset

  alias Gymrat.Repo
  alias Gymrat.Accounts.UserWeight

  def get_user_weight(user_weight_id) do
    query =
      from uw in UserWeight,
        where: uw.id == ^user_weight_id,
        where: is_nil(uw.deleted_at)

    case Repo.one(query) do
      %UserWeight{} = user_weight ->
        {:ok, user_weight}

      nil ->
        {:error, :not_found}
    end
  end

  def get_my_weights(user_id) do
    query =
      from uw in UserWeight,
        where: uw.user_id == ^user_id,
        where: is_nil(uw.deleted_at)

    Repo.all(query)
  end

  def get_todays_user_weights(user_id) do
    today = Date.utc_today()

    start_of_day = NaiveDateTime.new!(today, ~T[00:00:00])
    end_of_day = NaiveDateTime.new!(today, ~T[23:59:59])

    query =
      from uw in UserWeight,
        where:
          uw.inserted_at >= ^start_of_day and
            uw.inserted_at <= ^end_of_day and
            is_nil(uw.deleted_at) and
            uw.user_id == ^user_id

    Repo.all(query)
  end

  def get_weights_by_insertdate(user_id) do
    from(uw in UserWeight,
      where: is_nil(uw.deleted_at),
      where: uw.user_id == ^user_id,
      select: %{
        inserted_at: uw.inserted_at,
        weight: uw.weight
      },
      order_by: [asc: uw.inserted_at]
    )
    |> Repo.all()
  end

  def create_user_weight(attrs \\ %{}) do
    %UserWeight{}
    |> UserWeight.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_weight(%UserWeight{} = user_weight, attrs) do
    user_weight
    |> UserWeight.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_user_weight(%UserWeight{} = user_weight) do
    user_weight
    |> change(deleted_at: NaiveDateTime.local_now())
    |> Repo.update()
  end

  def change_user_weight(%UserWeight{} = user_weight, attrs \\ %{}) do
    UserWeight.changeset(user_weight, attrs)
  end

  def change_user_weight_map(attrs) do
    UserWeight.changeset(%UserWeight{}, attrs)
  end
end
