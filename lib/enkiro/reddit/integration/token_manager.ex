defmodule Enkiro.Reddit.Integration.TokenManager do
  @moduledoc """
  Manages the OAuth2 token for Reddit API access.
  """
  use Agent

  require Logger

  alias OAuth2.Client, as: OAuth2Client

  def start_link(_opts), do: Agent.start_link(fn -> nil end, name: __MODULE__)

  def get_token() do
    case Agent.get(__MODULE__, & &1) do
      # If token exists and is not expired (with a 60-second buffer)
      %{token: token, expires_at: expires_at} ->
        minute_from_now = Timex.now() |> Timex.shift(minutes: 1) |> Timex.to_unix()

        if expires_at > minute_from_now do
          {:ok, token}
        else
          # Token is expired or about to expire, fetch a new one
          fetch_and_store_new_token()
        end

      _ ->
        fetch_and_store_new_token()
    end
  end

  defp fetch_and_store_new_token() do
    Logger.debug("Fetching new Reddit API token...")
    config = Application.get_env(:enkiro, RedditFetcher)

    client =
      OAuth2Client.new(
        strategy: OAuth2.Strategy.ClientCredentials,
        client_id: config[:client_id],
        client_secret: config[:client_secret],
        site: "https://www.reddit.com",
        token_url: "/api/v1/access_token"
      )

    headers = [
      {"User-Agent", "Elixir:Enkiro.App:v0.1 (by /u/#{config[:username]})"}
    ]

    case OAuth2Client.get_token(client, [], headers) do
      {:ok, %{token: %OAuth2.AccessToken{access_token: token}}} ->
        decoded_response = Jason.decode!(token, keys: :atoms)

        expires_at =
          Timex.now()
          |> Timex.add(Timex.Duration.from_seconds(decoded_response.expires_in))
          |> Timex.to_unix()

        Agent.update(__MODULE__, fn _ ->
          %{token: decoded_response.access_token, expires_at: expires_at}
        end)

        {:ok, decoded_response.access_token}

      {:error, reason} ->
        Logger.error(reason, label: "Failed to get OAuth2 token")
        {:error, "Failed to authenticate with Reddit API"}
    end
  end
end
