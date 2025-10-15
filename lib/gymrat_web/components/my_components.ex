defmodule GymratWeb.MyComponents do
  use Phoenix.Component
  use Gettext, backend: GymratWeb.Gettext
  import GymratWeb.CoreComponents
  alias Phoenix.LiveView.JS

  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :string, required: false
  slot :inner_block, required: true

  def list_item(%{rest: rest} = assigns) do
    assigns =
      assigns
      |> assign(:rest, rest)
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <li class="bg-base-100">
      <%= if @rest[:href] || @rest[:navigate] || @rest[:patch] do %>
        <.link
          class={
            "mb-2 border rounded flex justify-between items-center group w-full items-stretch" <> @class
          }
          {@rest}
          tabindex="0"
        >
          <div class="py-2 ml-2 flex justify-start items-center">
            {render_slot(@inner_block)}
          </div>
          <span class="self-stretch flex pl-2 items-center  opacity-0 w-0 group-active:bg-primary/50 group-active:opacity-100 group-active:w-[35%] group-hover:bg-primary/50 group-hover:opacity-100 group-hover:w-[35%] group-focus:bg-primary/50 group-focus:opacity-100 group-focus:w-[35%] transition-all duration-300 ease-in-out overflow-hidden">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="currentColor"
              class="size-6"
            >
              <path
                fill-rule="evenodd"
                d="M12.97 3.97a.75.75 0 0 1 1.06 0l7.5 7.5a.75.75 0 0 1 0 1.06l-7.5 7.5a.75.75 0 1 1-1.06-1.06l6.22-6.22H3a.75.75 0 0 1 0-1.5h16.19l-6.22-6.22a.75.75 0 0 1 0-1.06Z"
                clip-rule="evenodd"
              />
            </svg>
          </span>
        </.link>
      <% else %>
        <div class="mb-2 p-2 w-full bg-base-100 border rounded flex justify-between items-center">
          {render_slot(@inner_block)}
        </div>
      <% end %>
    </li>
    """
  end

  attr :on_edit_navigate, :string, required: true
  attr :on_delete, :string, required: true
  attr :resource_id, :any, required: true
  attr :show_modal, :boolean, default: false
  attr :modal_id, :string, default: "confirm-modal"
  attr :resource_name, :string, required: true
  slot :modal_content, required: true

  def joined_action_group(assigns) do
    ~H"""
    <div class="join">
      <.link
        class="btn btn-primary btn-soft btn-square join-item"
        navigate={@on_edit_navigate}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          class="size-[1.2em]"
        >
          <path d="M21.731 2.269a2.625 2.625 0 0 0-3.712 0l-1.157 1.157 3.712 3.712 1.157-1.157a2.625 2.625 0 0 0 0-3.712ZM19.513 8.199l-3.712-3.712-12.15 12.15a5.25 5.25 0 0 0-1.32 2.214l-.8 2.685a.75.75 0 0 0 .933.933l2.685-.8a5.25 5.25 0 0 0 2.214-1.32L19.513 8.2Z" />
        </svg>
      </.link>

      <.link
        class="btn btn-error btn-soft btn-square join-item"
        phx-click={"show_modal_"<> @resource_name}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="currentColor"
          class="size-[1.2em]"
        >
          <path
            fill-rule="evenodd"
            d="M16.5 4.478v.227a48.816 48.816 0 0 1 3.878.512.75.75 0 1 1-.256 1.478l-.209-.035-1.005 13.07a3 3 0 0 1-2.991 2.77H8.084a3 3 0 0 1-2.991-2.77L4.087 6.66l-.209.035a.75.75 0 0 1-.256-1.478A48.567 48.567 0 0 1 7.5 4.705v-.227c0-1.564 1.213-2.9 2.816-2.951a52.662 52.662 0 0 1 3.369 0c1.603.051 2.815 1.387 2.815 2.951Zm-6.136-1.452a51.196 51.196 0 0 1 3.273 0C14.39 3.05 15 3.684 15 4.478v.113a49.488 49.488 0 0 0-6 0v-.113c0-.794.609-1.428 1.364-1.452Zm-.355 5.945a.75.75 0 1 0-1.5.058l.347 9a.75.75 0 1 0 1.499-.058l-.346-9Zm5.48.058a.75.75 0 1 0-1.498-.058l-.347 9a.75.75 0 0 0 1.5.058l.345-9Z"
            clip-rule="evenodd"
          />
        </svg>
      </.link>

      <.modal
        :if={@show_modal}
        id={@modal_id}
        on_cancel={JS.push("hide_modal")}
      >
        {render_slot(@modal_content)}
        <div class="modal-action">
          <.button phx-click={"hide_modal_"<> @resource_name}>
            Cancel
          </.button>
          <.button class="btn btn-error" phx-click={@on_delete} phx-value-id={@resource_id}>
            Confirm
          </.button>
        </div>
      </.modal>
    </div>
    """
  end

  attr :navigate, :string, required: true
  attr :title, :string, required: true

  def header_with_back_navigate(assigns) do
    ~H"""
    <div class="flex gap-2 items-center">
      <.button
        class="btn-soft btn-square stroke"
        navigate={@navigate}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          class="size-[1.2em] fill-primary/50"
        >
          <path
            fill-rule="evenodd"
            d="M9.53 2.47a.75.75 0 0 1 0 1.06L4.81 8.25H15a6.75 6.75 0 0 1 0 13.5h-3a.75.75 0 0 1 0-1.5h3a5.25 5.25 0 1 0 0-10.5H4.81l4.72 4.72a.75.75 0 1 1-1.06 1.06l-6-6a.75.75 0 0 1 0-1.06l6-6a.75.75 0 0 1 1.06 0Z"
            clip-rule="evenodd"
          />
        </svg>
      </.button>
      <h1 class="text-2xl font-bold">{@title}</h1>
    </div>
    """
  end
end
