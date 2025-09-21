# lib/gymrat_web/controllers/user_identify_controller.ex
defmodule GymratWeb.UserIdentifierController do
  use GymratWeb, :controller
  alias Gymrat.Training
  alias Gymrat.Users.User
  alias GymratWeb.UserIdentify

  # Show the identify form
  def new(conn, _params) do
    changeset = Training.change_user(%User{})
    render(conn, :new, changeset: changeset)
  end

  # Handle form submission
  def create(conn, %{"user" => user_params}) do
    case Training.get_or_create_user_by_name(user_params) do
      {:ok, user} ->
        conn
        # store in session
        |> UserIdentify.identify_user(user)
        # change to your landing page
        |> redirect(to: "/workouts")

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    conn
    |> UserIdentify.clear_identifier()
    # Redirect with string path
    |> redirect(to: "/")
  end
end
