defmodule GymratWeb.WeightLive.Edit do
  use GymratWeb, :live_view

  alias Gymrat.Training.UserWeights

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">Update Measurement</h1>

      <div class="mx-auto max-w-sm">
        <.form for={@form} id="weight_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:weight]}
            type="number"
            label="Weight (Kg)"
            placeholder="15.0"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Updating Measurement..." class="btn btn-primary w-full">
            Update Measurement
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        %{
          "id" => user_weight_id
        },
        _session,
        socket
      ) do
    user_weight_id = String.to_integer(user_weight_id)

    fetched_weight = UserWeights.get_user_weight(user_weight_id)

    case fetched_weight do
      {:ok, weight} ->
        changeset = UserWeights.change_user_weight(weight)

        socket =
          socket
          |> assign(weight: weight)
          |> assign_form(changeset)

        {:ok, socket}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @impl true
  def handle_event("save", %{"weight" => weight_params}, socket) do
    weight = socket.assigns.weight

    case UserWeights.update_user_weight(weight, weight_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The measurement was updated!"
          )
          |> push_navigate(to: ~p"/weights")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"weight" => weight_params}, socket) do
    weight = socket.assigns.weight
    changeset = UserWeights.change_user_weight(weight, weight_params)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "weight")
    assign(socket, :form, form)
  end
end
