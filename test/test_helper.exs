ExUnit.start()
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Enkiro.Repo, :manual)

Mox.defmock(Enkiro.Behaviors.HTTP.Mock, for: Enkiro.Behaviors.HTTP.Spec)
Mox.defmock(OAuth2.Client.MockHTTP, for: Enkiro.Behaviors.OAuth2.HTTPClient.Spec)
