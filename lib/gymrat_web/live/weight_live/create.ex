defmodule GymratWeb.WeightLive.Create do
  use GymratWeb, :live_view

  alias Gymrat.Training.UserWeights

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
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

          <.button phx-disable-with="Creating Weight..." class="btn btn-primary w-full">
            Add Weight
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        _payload,
        _session,
        socket
      ) do
    changeset = UserWeights.change_user_weight_map(%{})

    socket =
      socket
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user_weight" => user_weight_params}, socket) do
    user = socket.assigns.current_scope.user

    user_weight_params =
      user_weight_params
      |> Map.put("user_id", user.id)

    case UserWeights.create_user_weight(user_weight_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The weight was recorded!"
          )
          |> push_navigate(to: ~p"/weights")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user_weight" => user_weight_params}, socket) do
    changeset = UserWeights.change_user_weight_map(user_weight_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user_weight")
    assign(socket, form: form)
  end
end
