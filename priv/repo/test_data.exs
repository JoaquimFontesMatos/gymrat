alias Gymrat.Training.Sets

defmodule Gymrat.TestData do
  def seed_sets do
    users = [1, 2]
    workout_exercises = [1, 2]

    # helper to insert a set at a specific datetime
    insert_set = fn user_id, workout_exercise_id, datetime, weight, reps ->
      truncated_datetime = NaiveDateTime.truncate(datetime, :second)

      Sets.create_set(%{
        user_id: user_id,
        workout_exercise_id: workout_exercise_id,
        weight: weight,
        reps: reps,
        inserted_at: truncated_datetime,
        updated_at: truncated_datetime
      })
    end


    for user_id <- users do
      for workout_exercise_id <- workout_exercises do
        # -------- 2 months ago --------
        # Day 1 (weak)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-10-05], ~T[08:00:00]), 50, 10)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-10-05], ~T[09:00:00]), 55, 8)

        # Day 2 (strong → should survive)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-10-12], ~T[08:00:00]), 80, 5)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-10-12], ~T[09:00:00]), 85, 5)

        # -------- 3 months ago --------
        # Day 1 (weak)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-09-05], ~T[08:00:00]), 50, 10)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-09-05], ~T[09:00:00]), 55, 8)

        # Day 2 (strong → should survive)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-09-12], ~T[08:00:00]), 80, 5)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-09-12], ~T[09:00:00]), 85, 5)

        # Day 3 (newer and stronger → should survive)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-09-13], ~T[08:00:00]), 80, 5)
        insert_set.(user_id, workout_exercise_id, NaiveDateTime.new!(~D[2025-09-13], ~T[09:00:00]), 85, 5)
      end
    end

    :ok
  end
end
