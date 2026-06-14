# Run the tests
[group('dev')]
test:
    MIX_ENV=test infisical run --env=dev -- mix test

# Run the server
[group('dev')]
run:
    infisical run --env=dev -- mix phx.server

# Run the iex session
[group('dev')]
iex:
    infisical run --env=dev -- iex -S mix

[group('dev')]
deps-get:
    infisical run --env=dev -- mix deps.get

[group('dev')]
db-setup:
    infisical run --env=dev -- sh -c 'mix ecto.drop && mix ecto.create && mix ecto.migrate'

# Migrate the production (Aiven) database.
# MIX_ENV=prod is REQUIRED: config/runtime.exs only reads DATABASE_URL when
# config_env() == :prod, so without it the migration hits the local dev DB.
# Adjust --env if your Infisical production environment slug isn't "prod".
[group('prod')]
db-migrate-prod:
    MIX_ENV=prod infisical run --env=prod -- mix ecto.migrate
