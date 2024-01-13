defmodule MdsWeb.CommonComponents do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :messages, :list, required: true
  attr :class, :string, default: nil

  def logs(assigns) do
    ~H"""
    <div
      id={@id}
      phx-update="append"
      class={["text-sm overflow-scroll bg-slate-200 rounded-sm h-[85vh]", @class]}
      phx-hook="AutoScrollBottom"
    >
      <pre
        :for={message <- @messages}
        class={if message[:is_error], do: "text-red-800"}
        id={"msg-#{message.id}"}
      ><%= message.text %></pre>
    </div>
    """
  end
end
