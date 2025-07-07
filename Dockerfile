# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20250630-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.18.4-erlang-28.0.1-debian-bullseye-20250630-slim
#
ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=28.0.1
ARG DEBIAN_VERSION=bullseye-20250630-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ==============================================================================
# Base stage with build tools and Elixir tooling
# ==============================================================================
FROM ${BUILDER_IMAGE} AS base

# Install OS-level dependencies needed for building and development
RUN apt-get update -y && apt-get install -y \
    build-essential \
    libssl-dev \
    git \
    inotify-tools \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# ==============================================================================
# Deps stage to fetch and compile dependencies
# This creates a reusable, cached layer.
# ==============================================================================
FROM base AS deps

# Set build ENV for compiling dependencies
ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get

# Copy compile-time config before compiling to ensure config changes
# trigger a re-compile of dependencies.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# ==============================================================================
# Development stage: uses the pre-built deps
# ==============================================================================
FROM deps AS development

# Switch to dev environment
ENV MIX_ENV="dev"

# Copy the entire application source
COPY . .

# Compile the application for the dev environment.
# This step links the dependencies and prepares the app for Mix tasks.
RUN mix compile

# The CMD will use the already compiled dependencies from the `deps` stage.
# If mix.exs/lock changed, `deps` would be rebuilt, and we'd get the new deps.
CMD ["iex", "-S", "mix", "phx.server"]

# ==============================================================================
# Release stage: builds the final OTP release
# Also uses the pre-built deps.
# ==============================================================================
FROM deps AS release

# Set build ENV for the release build
ENV MIX_ENV="prod"

# Copy the rest of the application code
COPY priv priv
COPY lib lib
COPY assets assets

# Compile assets and the application
RUN mix assets.deploy
RUN mix compile

# Copy runtime config and release files
COPY config/runtime.exs config/
COPY rel rel

# Build the release
RUN mix release

# ==============================================================================
# Final stage: creates the small production image
# ==============================================================================
FROM ${RUNNER_IMAGE} AS final

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV MIX_ENV="prod"

WORKDIR /app
RUN chown nobody /app

# Copy only the compiled release from the release stage
COPY --from=release --chown=nobody:root /app/_build/${MIX_ENV}/rel/enkiro ./

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install`
# above and adding an entrypoint. See https://github.com/krallin/tini for details
# ENTRYPOINT ["/tini", "--"]

CMD ["/app/bin/server"]