# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Gymrat is a Phoenix 1.8 / LiveView fitness-tracking app (workout plans, exercises, sets, weight tracking, leaderboards). Deployed on Gigalixir.

## Read AGENTS.md first

`AGENTS.md` contains the authoritative Phoenix/Elixir/LiveView/Ecto coding rules for this project (auth scopes, HEEx syntax, forms, streams, testing conventions). Those rules are not repeated here — follow them. This file covers what AGENTS.md does not: the app's own architecture and workflow.

## Commands

- `mix setup` — install deps, create/migrate DB, build assets (first-time setup)
- `mix phx.server` / `iex -S mix phx.server` — run the app at `localhost:4000`
- `mix test` — run tests (auto-creates and migrates the test DB via the `test` alias)
- `mix test test/path/to/file_test.exs` — single file; `mix test path:LINE` for one test; `mix test --failed` to rerun failures
- `mix precommit` — **run before finishing any change**: `compile --warning-as-errors`, `deps.unlock --unused`, `format`, `test`
- `mix ecto.reset` — drop, recreate, migrate, seed

## Architecture

### Context / schema split (important and non-obvious)

Contexts (the public API — query and mutation functions) live under `lib/gymrat/training/`, namespace `Gymrat.Training.*`:
`Plans`, `Workouts`, `WorkoutExercises`, `Sets`, `UserWeights`.

Ecto **schemas** live in separate domain directories with *different* namespaces:
- `lib/gymrat/plans/` → `Gymrat.Plans.{Plan, UserPlans}`
- `lib/gymrat/workouts/` → `Gymrat.Workouts.{Workout, WorkoutWeekday, WorkoutExercise, Set}`
- `lib/gymrat/accounts/` → `Gymrat.Accounts.{User, UserToken, UserWeight, UserNotifier, Scope}`

So `Gymrat.Training.Plans` (context) operates on `Gymrat.Plans.Plan` (schema) — the names overlap but the modules are distinct. When adding domain logic, put functions in the `Training.*` context and the `schema`/`changeset` in the matching domain-named module. `Gymrat.Accounts` (`lib/gymrat/accounts.ex`) is the one context that follows the standard Phoenix layout.

### Soft deletes everywhere

Almost every schema has a `deleted_at` column. Deletes are soft (`change(deleted_at: NaiveDateTime.local_now())`), and **every query must filter `where: is_nil(x.deleted_at)`**. When writing new queries or joins, add the `is_nil(deleted_at)` guard for each joined table, matching existing context code.

### Authentication & scope

Uses `phx.gen.auth` with **scopes** (not a bare `current_user`). `@current_scope` is assigned by the `:browser` pipeline; access the user via `@current_scope.user`. Routes are split into `live_session :require_authenticated_user` (almost everything, including `/` → `PlanLive.Dashboard`) and `live_session :current_user` (register / log-in only). See AGENTS.md "Authentication" for the rules; see `lib/gymrat_web/router.ex` for the route map and `lib/gymrat_web/user_auth.ex` for the plugs/on_mount hooks.

### Web layer

LiveView-only — there is no JSON API (the `:api` scope is commented out). LiveViews are grouped by domain under `lib/gymrat_web/live/<domain>_live/` (e.g. `plan_live/`, `workout_live/`, `exercise_live/`, `set_live/`, `weight_live/`, `scoreboard_live/`, `user_live/`). Shared UI is in `lib/gymrat_web/components/` (`core_components.ex`, `my_components.ex`, `layouts.ex`).

### External exercise data

`Gymrat.ExerciseFetcher` calls the RapidAPI ExerciseDB service via `Req`. Credentials come from `config :gymrat, :rapidapi` (`RAPIDAPI_HOST` / `RAPIDAPI_KEY`). Exercises are referenced by an external `exercise_id`; users can also create **custom exercises** identified by `custom_name` instead — much context code branches on `if exercise_id do ... else (custom_name) ... end`.

### Background jobs (Oban)

Oban runs on Postgres. `Gymrat.Workers.SetCleanupWorker` runs weekly (`0 3 * * 0`, configured in `config/runtime.exs` crontab) and calls `Sets.smart_delete_old_sets/1`, which keeps the single heaviest-volume day per month for sets older than one month and prunes everything beyond ~12 months.

### Configuration & secrets

`config/config.exs` imports `config/.env.exs` and `config/.env.{env}.exs` if present (gitignored) for local secrets, then the env-specific config. Production secrets (DB, `RAPIDAPI_*`, `BREVO_API_KEY` mailer) are read from env vars in `config/runtime.exs`.

### Assets

esbuild + Tailwind **v4** (no `tailwind.config.js`; config is in `assets/css/app.css`). daisyUI and topbar are vendored under `assets/vendor/` and imported through `app.js`/`app.css`. Note: AGENTS.md discourages relying on daisyUI for design even though it is vendored here.
