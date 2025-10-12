defmodule GymratWeb.PlanLive.Import do
  use GymratWeb, :live_view

  alias Gymrat.Training.Plans
  import Ecto.Changeset

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <h1 class="text-2xl font-bold">Import a Plan</h1>

      <div class="mx-auto max-w-sm">
        <.form for={@form} id="import_plan_form" phx-submit="import">
          <.input
            field={@form[:share_token]}
            type="text"
            label="Share Token (UUID)"
            placeholder="Paste the plan's share token here"
            required
            phx-mounted={JS.focus()}
          />

          <.button phx-disable-with="Importing..." class="btn btn-primary w-full">
            Import Plan
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Schemaless changeset using cast
    changeset =
      {%{}, %{share_token: :string}}
      |> cast(%{}, [:share_token])

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("import", %{"import" => %{"share_token" => token}}, socket) do
    user_id = socket.assigns.current_scope.user.id

    case Plans.import_plan(token, user_id) do
      # On success, redirect to the new plan's detail page
      {:ok, imported_plan} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "The plan was imported successfully!")
          |> push_navigate(to: ~p"/plans/#{imported_plan.id}")
        }

      # Handle the case where the UUID is not found
      {:error, :not_found} ->
        changeset =
          {%{}, %{share_token: :string}}
          |> cast(%{"share_token" => token}, [:share_token])
          |> add_error(:share_token, "No plan found with this token.")

        {:noreply, assign_form(socket, changeset)}

      # Handle other potential errors (e.g., database issues)
      {:error, _reason} ->
        {
          :noreply,
          socket
          |> put_flash(:error, "An unexpected error occurred while importing.")
        }
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    # We use `as: "import"` to namespace our form parameters
    form = to_form(changeset, as: "import")
    assign(socket, form: form)
  end
end
