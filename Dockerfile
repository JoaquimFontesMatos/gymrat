# syntax=docker/dockerfile:1
#
# Multi-stage build for the `gymrat` mix release. Elixir 1.18.4 on OTP 28.0
# (the OTP gymrat already runs on under Gigalixir; also avoids an OTP 27.2 TLS
# bug that rejects Let's Encrypt's chain when fetching hex during the build).
# Both stages are Alpine (musl) so the ERTS shipped in the release links against
# the same libc as the runtime image.

ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=28.0
ARG ALPINE_VERSION=3.22.4
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}"
ARG RUNNER_IMAGE="alpine:${ALPINE_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# install build dependencies (nodejs+npm: gymrat's `assets.deploy` alias runs
# `cmd --cd assets npm install` before tailwind/esbuild)
RUN apk add --no-cache build-base git nodejs npm

WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

# install prod deps first (better layer caching)
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config before compiling deps
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

# compile assets (alias runs compile -> npm install -> tailwind --minify -> esbuild --minify -> phx.digest)
RUN mix assets.deploy

# compile the release
RUN mix compile

# runtime config + release overlays (rel/overlays/bin/{server,migrate})
COPY config/runtime.exs config/
COPY rel rel
RUN mix release

# ---- runtime image ----
FROM ${RUNNER_IMAGE}

RUN apk add --no-cache libstdc++ openssl ncurses-libs libgcc ca-certificates

# musl ships a UTF-8 capable C locale; no glibc locale-gen needed.
ENV LANG=C.UTF-8 LANGUAGE=C LC_ALL=C.UTF-8

WORKDIR /app

# non-root runtime user
RUN addgroup -S app && adduser -S -G app app && chown app:app /app

ENV MIX_ENV="prod"

# copy the built release from the builder
COPY --from=builder --chown=app:app /app/_build/${MIX_ENV}/rel/gymrat ./

USER app

# server overlay sets PHX_SERVER=true and execs `bin/gymrat start`
CMD ["/app/bin/server"]
