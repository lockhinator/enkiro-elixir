defmodule Enkiro.Reddit.Integration.APITest do
  use ExUnit.Case, async: true

  import Mox

  alias Enkiro.Behaviors.OAuth2.Mock, as: OAuth2Mock
  alias Enkiro.Reddit.Integration.TokenManager

  setup :verify_on_exit!

  setup do
    {:ok, _pid} = start_supervised({TokenManager, []})
    :ok
  end

  test "fetches and stores a new token" do
    expect(OAuth2Mock, :new, fn _, _ ->
      %OAuth2.Client{}
    end)

    expect(OAuth2Mock, :get_token, fn _, _, _, _ ->
      {:ok, %{token: %OAuth2.AccessToken{access_token: "test_token"}}}
    end)

    assert {:ok, "test_token"} = TokenManager.get_token()
  end

  test "returns cached token if available" do
    Agent.start_link(fn -> "cached_token" end, name: TokenManager)
    assert {:ok, "cached_token"} == TokenManager.get_token()
  end
end
