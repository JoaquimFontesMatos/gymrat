defmodule GymratWeb.Router do
  use GymratWeb, :router

  import GymratWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GymratWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", GymratWeb do
  #   pipe_through :api
  # end
  scope "/", GymratWeb do
    pipe_through :browser

    # get "/", PageController, :home
  end

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

  ## Authentication routes

  scope "/", GymratWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{GymratWeb.UserAuth, :require_authenticated}] do
      live "/", PlanLive.Dashboard, :dashboard
      live "/plans/new", PlanLive.Create, :new_plan
      live "/plans/:id", PlanLive.Details, :plan_details
      live "/plans/:id/edit", PlanLive.Edit, :edit_plan
      live "/plans/:id/workouts/new", WorkoutLive.Create, :new_workout
      live "/plans/:plan_id/workouts/:workout_id", WorkoutLive.Details, :workout_details
      live "/plans/:plan_id/workouts/:workout_id/edit", WorkoutLive.Edit, :edit_workout
      live "/plans/:plan_id/workouts/:workout_id/exercises/new", ExerciseLive.Add, :new_exercise

      live "/plans/:plan_id/workouts/:workout_id/exercises/:exercise_id",
           ExerciseLive.Details,
           :exercise_details

      live "/plans/:plan_id/workouts/:workout_id/exercises/:exercise_id/sets/new",
           SetLive.Create,
           :new_set

      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", GymratWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{GymratWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
