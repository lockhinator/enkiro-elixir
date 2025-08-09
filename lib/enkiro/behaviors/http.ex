defmodule Enkiro.Behaviors.HTTP.Spec do
  # HTTPoison accepts some other header types that NewRelic.Instrumented.HTTPoison does not.
  @type headers :: [{binary, binary}]

  @callback get(binary, headers, Keyword.t()) :: {:ok, map} | {:error, map}
  @callback post(binary, map, headers, Keyword.t()) :: {:ok, map} | {:error, map}
  @callback put(binary, map, headers, Keyword.t()) :: {:ok, map} | {:error, map}
  @callback patch(binary, map, headers, Keyword.t()) :: {:ok, map} | {:error, map}
  @callback delete(binary, headers, Keyword.t()) :: {:ok, map} | {:error, map}
end

defmodule Enkiro.Behaviors.HTTP.HTTPoison do
  @behaviour Enkiro.Behaviors.HTTP.Spec

  defdelegate get(url, headers \\ [], options \\ []), to: HTTPoison
  defdelegate post(url, body, headers \\ [], options \\ []), to: HTTPoison
  defdelegate put(url, body, headers \\ [], options \\ []), to: HTTPoison
  defdelegate patch(url, body, headers \\ [], options \\ []), to: HTTPoison
  defdelegate delete(url, headers \\ [], options \\ []), to: HTTPoison
end

defmodule Enkiro.Behaviors.HTTP do
  @behaviour Enkiro.Behaviors.HTTP.Spec
  @provider Application.compile_env(:enkiro, __MODULE__)[:provider]

  defdelegate get(url, headers \\ [], options \\ []), to: @provider
  defdelegate post(url, body, headers \\ [], options \\ []), to: @provider
  defdelegate put(url, body, headers \\ [], options \\ []), to: @provider
  defdelegate patch(url, body, headers \\ [], options \\ []), to: @provider
  defdelegate delete(url, headers \\ [], options \\ []), to: @provider
end

defmodule Enkiro.Behaviors.OAuth2.HTTPClient.Spec do
  @moduledoc """
  Behaviour specification for OAuth2 HTTP client adapter
  """

  @type method :: :get | :post | :put | :patch | :delete
  @type headers :: [{String.t(), String.t()}]
  @type body :: String.t() | map()
  @type opts :: Keyword.t()

  @callback request(
              method,
              url :: String.t(),
              headers,
              body,
              opts
            ) :: {:ok, OAuth2.Response.t()} | {:error, OAuth2.Error.t()}

  @callback call(Tesla.Env.t(), opts) ::
              {:ok, Tesla.Env.t()}
              | {:error, any()}
end
