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

Start the Enkiro app in the background with:

```bash
docker compose up -d
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

--
## Creating Your User

To create a user run the following:

```bash
docker compose run --rm app
iex> Enkiro.Accounts.register_user(%{email: "test@test.com", password: "password123password123"})
```

--
## 📚 Official Phoenix Resources

* [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
* [Phoenix Website](https://www.phoenixframework.org/)
* [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
* [Phoenix Docs](https://hexdocs.pm/phoenix)
* [Elixir Forum – Phoenix](https://elixirforum.com/c/phoenix-forum)
* [Phoenix GitHub Repo](https://github.com/phoenixframework/phoenix)
