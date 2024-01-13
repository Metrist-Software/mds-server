defmodule MdsWeb.Router do
  use MdsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MdsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :check_api_token
  end

  pipeline :require_user do
    plug :require_user_plug
  end

  pipeline :require_admin_user do
    plug :require_admin_user_plug
  end

  pipeline :require_no_user do
    plug :require_no_user_plug
  end

  scope "/", MdsWeb do
    pipe_through :browser
    pipe_through :require_user

    live_session :user, on_mount: {MdsWeb.InitAssigns, :user} do
      live "/", Live.Home, :index
      live "/new", Live.Home, :new

      live "/projects", ProjectLive.Index, :index
      live "/projects/new", ProjectLive.Index, :new
      live "/projects/:project_id/edit", ProjectLive.Index, :edit
      live "/projects/:project_id", ProjectLive.Show, :show
      live "/projects/:project_id/delete", ProjectLive.Delete
      live "/projects/:project_id/show/edit", ProjectLive.Show, :edit
      live "/projects/:project_id/:environment_id/up", ProjectLive.Up, :up
      live "/projects/:project_id/:environment_id/deploy", ProjectLive.Deploy, :deploy
      live "/projects/:project_id/:environment_id/history", ProjectLive.History, :history
      live "/projects/:project_id/doc", ProjectLive.Doc, :doc

      live "/resources/:project_id/", ResourceLive.Index, :index
      live "/resources/:project_id/new", ResourceLive.Index, :new
      live "/resources/:project_id/:resource_id/edit", ResourceLive.Index, :edit
      live "/resources/:project_id/:resource_id", ResourceLive.Show, :show
      live "/resources/:project_id/:resource_id/show/edit", ResourceLive.Show, :edit

      live "/environments/:project_id/", EnvironmentLive.Index, :index
      live "/environments/:project_id/new", EnvironmentLive.Index, :new
      live "/environments/:project_id/:environment_id/edit", EnvironmentLive.Index, :edit
      # live "/environments/:project_id/:environment_id/delete", EnvironmentLive.Delete
      live "/environments/:project_id/:environment_id", EnvironmentLive.Show, :show
      live "/environments/:project_id/:environment_id/show/edit", EnvironmentLive.Show, :edit

      live "/deployments/:deployment_id/log", DeploymentLive.Log, :log

      live "/self/change_account", SelfLive.ChangeAccount, :index
      get "/self/do_change_account/:account_id", Controllers.ChangeAccount, :index
      live "/self/profile", SelfLive.Profile, :index
    end
  end

  scope "/", MdsWeb do
    pipe_through :browser
    pipe_through :require_admin_user

    live_session :admin_user, on_mount: {MdsWeb.InitAssigns, :admin_user} do
      live "/accounts", AccountLive.Index, :index
      live "/accounts/new", AccountLive.Index, :new
      live "/accounts/:id/edit", AccountLive.Index, :edit
      live "/accounts/:id", AccountLive.Show, :show
      live "/accounts/:id/show/edit", AccountLive.Show, :edit

      live "/users", UserLive.Index, :index
      live "/users/new", UserLive.Index, :new
      live "/users/:id/edit", UserLive.Index, :edit
      live "/users/:id", UserLive.Show, :show
      live "/users/:id/show/edit", UserLive.Show, :edit
    end
  end

  scope "/", MdsWeb do
    pipe_through :browser
    pipe_through :require_no_user

    live_session :public, on_mount: {MdsWeb.InitAssigns, :public} do
      live "/login", Live.Login
    end
  end

  scope "/auth", MdsWeb.Controllers do
    pipe_through :browser

    get "/signout", AuthController, :signout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  scope "/api", MdsWeb.Controllers do
    pipe_through :api

    post "/:project_id/:environment_id/deploy", DeploymentController, :post
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mds_server, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MdsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  def require_user_plug(conn, _opts) do
    user = get_session(conn, :user)

    if is_nil(user) do
      redirect_to_login(conn)
    else
      conn
    end
  end

  def require_admin_user_plug(conn, _opts) do
    # user = get_session(conn, :user)

    # TODO implement
    redirect_to_index(conn)
  end

  def require_no_user_plug(conn, _opts) do
    user = get_session(conn, :user)

    case user do
      nil ->
        conn

      _user ->
        redirect_to_index(conn)
    end
  end

  # Todo: actual login screen with auth provider selection.
  defp redirect_to_login(conn) do
    conn
    |> redirect(to: "/login")
    |> halt()
  end

  defp redirect_to_index(conn) do
    conn
    |> redirect(to: "/")
    |> halt()
  end

  defp check_api_token(conn, _opts) do
    token = bearer_token(conn)

    case MdsData.Accounts.get_owner(token) do
      nil ->
        conn
        |> send_resp(401, ~s({"error": "Forbidden"}))
        |> halt()
      %MdsData.Accounts.User{} = user ->
        account_ids = MdsData.Accounts.account_ids_for(user)

        conn
        |> put_session(:user_id, user.id)
        |> put_session(:account_ids, account_ids)
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      [] -> ""
      [h | _] -> h
      |> String.replace("Bearer", "")
      |> String.trim()
    end
  end
end
