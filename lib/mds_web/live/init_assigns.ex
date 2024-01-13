defmodule MdsWeb.InitAssigns do
  use MdsWeb, :live_view

  def on_mount(user_type, _params, session, socket) do
    socket = copy_session(socket, session)

    if validate_user_type(user_type, socket) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: redirect_path(user_type))}
    end
  end

  def render(assigns) do
    ~H""
  end

  defp copy_session(socket, session) do
    Phoenix.Component.assign(socket,
      user: session["user"],
      account: session["account"]
    )
  end

  defp validate_user_type(:user, %{assigns: %{user: %{id: _id}}}),
    do: true

  defp validate_user_type(:public, %{assigns: %{user: nil}}),
    do: true

  defp validate_user_type(_, _),
    do: false

  @spec redirect_path(:user) :: <<_::8>>
  def redirect_path(:user), do: "/"
end
