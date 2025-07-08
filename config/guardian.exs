import Config

config :enkiro, Enkiro.Guardian,
  issuer: "enkiro",
  # The secret_key will be loaded from the environment in runtime.exs
  secret_key: nil,
  ttl: {15, :minute},
  module: Enkiro.Guardian,
  error_handler: Enkiro.AuthErrorHandler,
  hooks: Guardian.DB,
  db_module: Enkiro.Guardian.Token,
  repo: Enkiro.Repo
