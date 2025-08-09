defmodule Enkiro.Reddit.Integration.TokenManagerTest do
  use ExUnit.Case, async: true

  import Mox

  alias ExUnit.CaptureLog
  alias OAuth2.Client.MockHTTP
  alias Enkiro.Reddit.Integration.TokenManager

  @reddit_config [
    client_id: "test_client_id",
    client_secret: "test_client_secret",
    username: "test_user"
  ]

  setup :verify_on_exit!

  setup do
    Application.put_env(:enkiro, RedditFetcher, @reddit_config)
    {:ok, _pid} = start_supervised(TokenManager)
    :ok
  end

  describe "get_token/0" do
    test "fetches new token when no token exists" do
      MockHTTP
      |> expect(:call, fn %Tesla.Env{
                            method: :post,
                            url: "https://www.reddit.com/api/v1/access_token",
                            body: "grant_type=client_credentials"
                          } = env,
                          _opts ->
        {:ok,
         %Tesla.Env{
           env
           | status: 200,
             body: "{\"access_token\":\"new_test_token\",\"expires_in\":3600}",
             headers: [{"content-type", "application/json"}]
         }}
      end)

      assert {:ok, "new_test_token"} = TokenManager.get_token()
    end

    test "returns cached token when not expired" do
      future_expiry =
        Timex.now()
        |> Timex.shift(hours: 1)
        |> Timex.to_unix()

      :sys.replace_state(TokenManager, fn _ ->
        %{token: "cached_token", expires_at: future_expiry}
      end)

      assert {:ok, "cached_token"} = TokenManager.get_token()
    end

    test "fetches new token when current token is expired" do
      past_expiry =
        Timex.now()
        |> Timex.shift(minutes: -5)
        |> Timex.to_unix()

      :sys.replace_state(TokenManager, fn _ ->
        %{token: "expired_token", expires_at: past_expiry}
      end)

      MockHTTP
      |> expect(:call, fn %Tesla.Env{
                            method: :post,
                            url: "https://www.reddit.com/api/v1/access_token",
                            body: "grant_type=client_credentials"
                          } = env,
                          _opts ->
        {:ok,
         %Tesla.Env{
           env
           | status: 200,
             body: "{\"access_token\":\"refreshed_token\",\"expires_in\":3600}",
             headers: [{"content-type", "application/json"}]
         }}
      end)

      assert {:ok, "refreshed_token"} = TokenManager.get_token()
    end

    test "handles error from OAuth client" do
      MockHTTP
      |> expect(:call, fn %Tesla.Env{
                            method: :post,
                            url: "https://www.reddit.com/api/v1/access_token"
                          } = env,
                          _opts ->
        {:ok,
         %Tesla.Env{
           env
           | status: 401,
             body: "{\"error\":\"unauthorized\"}",
             headers: [{"content-type", "application/json"}]
         }}
      end)

      CaptureLog.capture_log(fn ->
        assert {:error, "Failed to authenticate with Reddit API"} = TokenManager.get_token()
      end) =~ "unauthorized"
    end
  end
end
