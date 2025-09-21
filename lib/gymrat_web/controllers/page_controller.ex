defmodule GymratWeb.PageController do
  use GymratWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
