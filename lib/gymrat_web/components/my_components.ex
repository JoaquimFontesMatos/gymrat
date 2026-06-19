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
    <li>
      <%= if @rest[:href] || @rest[:navigate] || @rest[:patch] do %>
        <.link
          class={
            "relative mb-2 flex justify-between group w-full items-stretch border border-base-300 rounded-xl transition-shadow shadow-sm" <> @class
          }
          {@rest}
          tabindex="0"
        >
          <div class="flex justify-start items-center ml-2 py-2 h-full">
            {render_slot(@inner_block)}
          </div>
          <span class="right-0 absolute inset-y-0 flex items-center group-active:bg-primary/50 group-focus:bg-primary/50 group-hover:bg-primary/50 opacity-0 group-active:opacity-100 group-focus:opacity-100 group-hover:opacity-100 shadow-primary/50 shadow-sm pl-2 rounded-r-xl w-0 group-active:w-[35%] group-focus:w-[35%] group-hover:w-[35%] overflow-hidden transition-all duration-300 ease-in-out">
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
        <div class="flex justify-between items-center bg-base-100 shadow-sm mb-2 p-2 border border-base-300 rounded-xl w-full transition-shadow">
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
    <div class="flex items-center gap-2">
      <.button
        class="btn-soft btn-square stroke"
        navigate={@navigate}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          class="fill-primary/50 size-[1.2em]"
        >
          <path
            fill-rule="evenodd"
            d="M9.53 2.47a.75.75 0 0 1 0 1.06L4.81 8.25H15a6.75 6.75 0 0 1 0 13.5h-3a.75.75 0 0 1 0-1.5h3a5.25 5.25 0 1 0 0-10.5H4.81l4.72 4.72a.75.75 0 1 1-1.06 1.06l-6-6a.75.75 0 0 1 0-1.06l6-6a.75.75 0 0 1 1.06 0Z"
            clip-rule="evenodd"
          />
        </svg>
      </.button>
      <h1 class="font-bold text-2xl">{@title}</h1>
    </div>
    """
  end

  @doc """
  Renders a ranked leaderboard table.

  Each row is a map with a `:user` (carrying at least `:name`) and a `:value`
  (a pre-formatted string such as `"1000 kg"`). The top three rows are tinted
  and get a medal. `value_header` labels the metric column (e.g. `"Volume"`).
  """
  attr :rows, :list, required: true
  attr :value_header, :string, required: true

  def scoreboard_table(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="table">
        <thead>
          <tr>
            <th></th>
            <th>Name</th>
            <th>{@value_header}</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{row, index} <- Enum.with_index(@rows)} class={"size-5 " <> rank_row_class(index)}>
            <th>{index + 1}</th>
            <td>{row.user.name}</td>
            <td>{row.value}</td>
            <td>
              <svg
                :if={index < 3}
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                class={"size-5 " <> medal_class(index)}
              >
                <path
                  fill-rule="evenodd"
                  d="M5.166 2.621v.858c-1.035.148-2.059.33-3.071.543a.75.75 0 0 0-.584.859 6.753 6.753 0 0 0 6.138 5.6 6.73 6.73 0 0 0 2.743 1.346A6.707 6.707 0 0 1 9.279 15H8.54c-1.036 0-1.875.84-1.875 1.875V19.5h-.75a2.25 2.25 0 0 0-2.25 2.25c0 .414.336.75.75.75h15a.75.75 0 0 0 .75-.75 2.25 2.25 0 0 0-2.25-2.25h-.75v-2.625c0-1.036-.84-1.875-1.875-1.875h-.739a6.706 6.706 0 0 1-1.112-3.173 6.73 6.73 0 0 0 2.743-1.347 6.753 6.753 0 0 0 6.139-5.6.75.75 0 0 0-.585-.858 47.077 47.077 0 0 0-3.07-.543V2.62a.75.75 0 0 0-.658-.744 49.22 49.22 0 0 0-6.093-.377c-2.063 0-4.096.128-6.093.377a.75.75 0 0 0-.657.744Zm0 2.629c0 1.196.312 2.32.857 3.294A5.266 5.266 0 0 1 3.16 5.337a45.6 45.6 0 0 1 2.006-.343v.256Zm13.5 0v-.256c.674.1 1.343.214 2.006.343a5.265 5.265 0 0 1-2.863 3.207 6.72 6.72 0 0 0 .857-3.294Z"
                  clip-rule="evenodd"
                />
              </svg>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp rank_row_class(0), do: "text-yellow-500 bg-yellow-600/15"
  defp rank_row_class(1), do: "text-slate-500 bg-slate-600/15"
  defp rank_row_class(2), do: "text-amber-800 bg-amber-900/15"
  defp rank_row_class(_), do: ""

  defp medal_class(0), do: "text-yellow-500 stroke-yellow-600"
  defp medal_class(1), do: "text-slate-500 stroke-slate-600"
  defp medal_class(2), do: "text-amber-800 stroke-amber-900"
  defp medal_class(_), do: ""

  @doc """
  Renders a weekday picker as a row of toggleable day buttons.

  Backed by a `{:array, :integer}` form field where each weekday is
  represented by its ISO day number (Monday = 1 … Sunday = 7). Selected
  days submit under `<field>[]`; when none are selected the param is
  omitted, matching the previous `<select multiple>` behaviour.
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: "Days to schedule"

  def weekday_picker(assigns) do
    selected =
      (assigns.field.value || [])
      |> List.wrap()
      |> Enum.map(fn
        n when is_integer(n) -> n
        n when is_binary(n) -> String.to_integer(n)
      end)

    errors =
      if Phoenix.Component.used_input?(assigns.field),
        do: assigns.field.errors,
        else: []

    assigns = assign(assigns, selected: selected, errors: errors)

    ~H"""
    <fieldset class="mt-4">
      <legend class="text-xs text-gray-400 mb-1">{@label}</legend>
      <div class="grid grid-cols-7 gap-1.5">
        <label
          :for={{name, num} <- weekday_options()}
          class="cursor-pointer select-none rounded-lg border border-base-300 py-2.5 flex items-center justify-center text-center transition-colors hover:bg-base-200 has-[:checked]:border-primary has-[:checked]:bg-primary has-[:checked]:text-primary-content has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-primary"
        >
          <input
            type="checkbox"
            name={@field.name <> "[]"}
            value={num}
            checked={num in @selected}
            class="sr-only"
          />
          <span class="text-xs font-semibold uppercase tracking-wide">{name}</span>
        </label>
      </div>
      <p :for={error <- @errors} class="mt-1.5 flex gap-2 items-center text-sm text-error">
        <.icon name="hero-exclamation-circle" class="size-5" />
        {translate_error(error)}
      </p>
    </fieldset>
    """
  end

  defp weekday_options do
    [
      {"Mon", 1},
      {"Tue", 2},
      {"Wed", 3},
      {"Thu", 4},
      {"Fri", 5},
      {"Sat", 6},
      {"Sun", 7}
    ]
  end
end
