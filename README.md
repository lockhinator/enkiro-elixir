# Enkiro

Enkiro is an Elixir + Phoenix application. This guide helps you get the app running locally using Docker and Docker Compose.

---

## 🚀 Getting Started

### ✅ Prerequisites

* [Install Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)
* Create a persistent volume for PostgreSQL:

```bash
docker volume create --name=pg-data
```

This ensures your local database retains data between container restarts.

---

### ▶️ Start the Application

1. **Set up Local Development Configuration**

   For local development, you need to create a docker-compose.override.yml file. This file adds settings like port mapping and volume mounts for live code reloading. A template is provided for you.

   Copy the example docker compose override file:

   ```bash
   cp docker-compose.override.yml.example docker-compose.override.yml
   ```

   Copy the `.env` file:

   ```bash
   cp .env.example .env
   ```

   #### Generate Needed Keys

   Generate the token for the `SECRET_KEY_BASE` environment variable using `mix phx.gen.secret`. Add it to the key in your `.env` file.

   Generate the token for the `GUARDIAN_SECRET_KEY` environment variable using `mix guardian.gen.secret`. Add it to the key in your `.env` file.

2. **Start the Application**

   Start the Enkiro app in the background with:

   ```bash
   docker compose up -d
   ```
3. **Creating Your User**

   To create a user run the following:

   ```bash
   docker compose run --rm app
   iex> Enkiro.Accounts.register_user(%{email: "test@test.com", password: "password123password123"})
   ```

Once running, visit [http://localhost:4000](http://localhost:4000) in your browser to verify it’s working.

---

## 💻 Access the IEx Terminal

To run code or debug interactively via the Elixir IEx shell:

1. Stop the background app if it's running:

   ```bash
   docker compose stop app
   # or
   docker compose down
   ```

2. Start an interactive IEx session:

   ```bash
   docker compose run --rm app
   ```

This launches the app in the foreground and opens an interactive terminal session.

---

## 🧪 Running Automated Tests

To run the automated test suite:

```bash
docker compose run --rm app /bin/bash -c "MIX_ENV=test mix test"
```

---

## 🤖 Continuous Integration (CI) Pipeline

The CI pipeline is built on GitHub Actions and is designed to be efficient, secure, and reliable. The configuration is split between two workflow files, `.github/workflows/test.yaml` and `.github/workflows/build.yaml`, which are powered by a highly optimized `Dockerfile`.

### Key Principles

Several key decisions were made to ensure the pipeline is as fast and efficient as possible:

* **Multi-Stage Docker Builds**: The `Dockerfile` is split into multiple stages (`base`, `deps`, `development`, `release`, `final`). This allows us to build dependencies and application code in temporary stages that can be discarded, ensuring the final production image is minimal.

* **Dependency Caching**: A dedicated `deps` stage fetches and compiles all project dependencies. Docker caches this layer, so dependencies are only re-compiled when the `mix.lock` file changes, dramatically speeding up most CI runs.

* **Efficient Test Execution**: To minimize CI runtime costs, the test workflow combines database creation, migration, and the test run into a single `docker compose run` command. This avoids the overhead of starting the Elixir application multiple times.

* **Secure Test File Handling**: The `test/` directory is intentionally included in the build context so that the CI pipeline can run automated tests against the `development` image. However, these files are automatically excluded from the final production image. This is because the `mix release` command intelligently packages only production-necessary code, and our `final` Docker stage only copies this lean, pre-packaged release artifact, ensuring no test code ever ships to production.

* **Lean Production Images**: The `final` stage of the `Dockerfile` starts with a fresh, minimal base image and copies **only** the compiled release artifact from the `release` stage. This practice ensures the production image is as small and secure as possible, containing no build tools, source code, or test files.

### Workflow Breakdown

1. **Test Workflow (`test.yaml`)**

   * **Trigger**: Runs on every push to any branch that is **not** `main`.

   * **Goal**: To validate that the code is correct and all tests pass.

   * **Process**:

     * Builds the `development` image from the `Dockerfile`.

     * Runs database migrations and the full `mix test` suite within that image.

2. **Build Workflow (`build.yaml`)**

   * **Trigger**: Runs only on pushes to the `main` branch.

   * **Goal**: To build the final, production-ready Docker image.

   * **Process**:

     * Builds the `final` image from the `Dockerfile`.

     * This image is ready to be pushed to a container registry (like Docker Hub or GHCR) for deployment.

   * **Image Pushing and Tagging**:

      * The workflow pushes two versions of the image to ensure both ease of use and the ability to perform precise rollbacks:

         * `:latest`: A rolling tag that always points to the most recent successful build from the `main` branch.

         *  **Git SHA Tag**: A unique, immutable tag based on the commit hash (e.g., `:a1b2c3d4`). This allows you to deploy or roll back to a specific version of the code with confidence.

---

## 📚 Official Phoenix Resources

* [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
* [Phoenix Website](https://www.phoenixframework.org/)
* [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
* [Phoenix Docs](https://hexdocs.pm/phoenix)
* [Elixir Forum – Phoenix](https://elixirforum.com/c/phoenix-forum)
* [Phoenix GitHub Repo](https://github.com/phoenixframework/phoenix)
