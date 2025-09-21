defmodule GymratWeb.Router do
  use GymratWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GymratWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GymratWeb do
    pipe_through :browser

    get "/", PageController, :home
    # Form to set name
    get "/identify", UserIdentifierController, :new
    # Process name
    post "/identify", UserIdentifierController, :create
    live "/workouts", WorkoutLive.Index
  end

  scope "/api", GymratWeb do
    pipe_through :api

    # Exercises (real-time)
    get "/exercises", ExerciseController, :index
    get "/exercises/:id", ExerciseController, :show

    # Workouts / Sets (user data)
    resources "/workouts", WorkoutController, only: [:create, :show]
    # resources "/sets", SetController, only: [:index, :create]
    # resources "/users", UserController, only: [:index, :create]
  end

  # Other scopes may use custom stacks.
  # scope "/api", GymratWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:gymrat, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GymratWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
