defmodule Gymrat.Training do
  import Ecto.Query, warn: false
  alias Gymrat.Repo

  alias Gymrat.Plans.Plan
  alias Gymrat.Users.User
  alias Gymrat.Workouts.{Workout, WorkoutExercise, Set}

  # ---------------------------
  # Users
  # ---------------------------
  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  # Modified to create or find a user by name
  def get_or_create_user_by_name(name) do
    case Repo.get_by(User, name: name) do
      %User{} = user ->
        # User found, return it
        {:ok, user}

      nil ->
        # User not found, try to create a new one
        # Only name is strictly required here for identification
        attrs = %{"name" => name}

        %User{}
        # Use the generic changeset
        |> User.changeset(attrs)
        |> Repo.insert()
    end
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  # def update_user(%User{} = user, attrs) do
  # user
  #  # Use update_changeset if you have one
  # |> User.update_changeset(attrs)
  #  |> Repo.update()
  # end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def get_user_by_name(name) do
    Repo.get_by(User, name: name)
  end

  # ---------------------------
  # Plans
  # ---------------------------
  def list_plans do
    Repo.all(Plans)
  end

  def get_plan!(id) do
    Repo.get!(Plan, id)
  end

  def create_plan(attrs \\ %{}) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  # Workouts
  # ---------------------------
  def list_workouts do
    Repo.all(Workout)
  end

  def get_workout!(id) do
    Repo.get!(Workout, id)
    |> Repo.preload([:workout_exercises, workout_exercises: :sets])
  end

  def create_workout(attrs \\ %{}) do
    %Workout{}
    |> Workout.changeset(attrs)
    |> Repo.insert()
  end

  # ---------------------------
  # WorkoutExercises
  # ---------------------------
  def list_workout_exercises do
    Repo.all(WorkoutExercise)
  end

  def create_workout_exercise(attrs \\ %{}) do
    %WorkoutExercise{}
    |> WorkoutExercise.changeset(attrs)
    |> Repo.insert()
  end

  # ---------------------------
  # Sets
  # ---------------------------
  def list_sets do
    Repo.all(Set)
  end

  def create_set(attrs \\ %{}) do
    %Set{}
    |> Set.changeset(attrs)
    |> Repo.insert()
  end

  # Preload sets for a workout (through workout_exercises)
  def preload_sets(workout) do
    Repo.preload(workout, workout_exercises: :sets)
  end
end
