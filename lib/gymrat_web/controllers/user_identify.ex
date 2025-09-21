defmodule GymratWeb.UserIdentify do
  import Plug.Conn
  import Phoenix.Controller

  alias Gymrat.Users.User
  alias Gymrat.Repo

  @session_key :user_id

  def identify_user(conn, user) do
    conn
    |> put_session(@session_key, user.id)
    |> configure_session(renew: true)
    |> put_flash(:info, "Welcome, #{user.name}!")
  end

  def clear_identifier(conn) do
    conn
    |> delete_session(@session_key)
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been cleared.")
  end

  def fetch_current_user(conn, _opts) do
    if user_id = get_session(conn, @session_key) do
      conn
      |> assign(:current_user, Repo.get(User, user_id))
    else
      conn
    end
  end

  def require_identified_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must provide a name to proceed.")
      # String path for redirect from the plug
      |> redirect(to: "/identify")
      |> halt()
    end
  end

  def identified?(conn), do: conn.assigns[:current_user] != nil
end
