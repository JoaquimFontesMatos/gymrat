defmodule GymratWeb.HeaderComponent do
  use Phoenix.LiveComponent

  @moduledoc """
  A header component that shows the current user's name.
  """

  def render(assigns) do
    ~H"""
    <header class="p-4 flex justify-between items-center">
      <h1 class="text-xl font-bold">Gymrat</h1>
      <div>
        <%= if @current_user do %>
          Logged in as: <strong>{@current_user.name}</strong>
        <% else %>
          Not logged in
        <% end %>
      </div>
    </header>
    """
  end
end
