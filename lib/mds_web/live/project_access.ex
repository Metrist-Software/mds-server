defmodule MdsWeb.Live.ProjectAccess do
  @doc """
  Unhygienic macro that expects `params` and `socket` to be in the
  calling environment; it'll check whether the project is accessible
  by the user under their current account and execute the do block
  if true. In the latter case, the variable `project` is set for the
  do block.
  """
  defmacro if_accessible_project(do: block) do
    quote do
      var!(project) = MdsData.Projects.get_project!(var!(params)["project_id"])
      if var!(project).account_id != var!(socket).assigns.account.id do
        var!(socket)
        |> put_flash(:error, "You are not allowed to view this project")
        |> redirect(to: "/")
      else
        unquote(block)
      end
    end
  end
end
