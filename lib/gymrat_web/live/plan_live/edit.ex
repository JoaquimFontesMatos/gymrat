defmodule GymratWeb.PlanLive.Edit do
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
            placeholder="Enter new plan name"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Updating plan..." class="btn btn-primary w-full">
            Update the Plan
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => plan_id}, _session, socket) do
    plan_id = String.to_integer(plan_id)

    plan = Training.get_plan!(plan_id)
    changeset = Training.change_plan(plan)

    socket =
      socket
      |> assign(:plan, plan)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"plan" => plan_params}, socket) do
    plan = socket.assigns.plan

    case Training.update_plan(plan, plan_params) do
      {:ok, updated_plan} ->
        {
          :noreply,
          socket
          |> put_flash(
            :info,
            "The plan was updated!"
          )
          |> push_navigate(to: ~p"/plans/#{updated_plan.id}")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"plan" => plan_params}, socket) do
    plan = socket.assigns.plan
    changeset = Training.change_plan(plan, plan_params)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "plan")
    assign(socket, :form, form)
  end
end
