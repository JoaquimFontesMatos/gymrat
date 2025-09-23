defmodule GymratWeb.PlanLive.Create do
  use GymratWeb, :live_view

  alias Gymrat.Training

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.form for={@form} id="plan_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:name]}
            type="text"
            label="Plan Name"
            placeholder="Enter plan name"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Creating plan..." class="btn btn-primary w-full">
            Create a Plan
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Training.change_plan(%{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"plan" => plan_params}, socket) do
    # Access the user from the socket's assigns
    user = socket.assigns.current_scope.user

    plan_params = Map.put(plan_params, "creator_id", user.id)

    case Training.create_plan(plan_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The plan was created!"
          )
          |> push_navigate(to: ~p"/")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"plan" => plan_params}, socket) do
    changeset = Training.change_plan(plan_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "plan")
    assign(socket, form: form)
  end
end
