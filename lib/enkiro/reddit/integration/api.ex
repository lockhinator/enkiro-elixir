defmodule Enkiro.Reddit.Integration.Api do
  @moduledoc """
  A module to fetch all posts and their comments from a given subreddit for a specific day
  using authenticated Reddit API requests.
  """
  require Logger
  alias Enkiro.Reddit.Integration.TokenManager

  @oauth_url "https://oauth.reddit.com"

  def posts_for_day(subreddit, date, limit \\ 1000) do
    {start_timestamp, end_timestamp} = calculate_timestamp_range(date)
    search_url =
      "#{@oauth_url}/r/#{subreddit}/top.json?q=timestamp:#{start_timestamp}..#{end_timestamp}&restrict_sr=on&sort=new&syntax=cloudsearch&limit=#{limit}"
    fetch_all_posts(search_url)
  end

  defp fetch_all_posts(url, acc \\ []) do
    with {:ok, headers} <- headers() do
      case HTTPoison.get(url, headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, data} = Jason.decode(body)
          children = get_in(data, ["data", "children"]) |> Enum.map(& &1["data"])
          new_acc = acc ++ children
          after_value = get_in(data, ["data", "after"])

          if after_value do
            next_url = "#{url}&after=#{after_value}"
            Process.sleep(1000) # Respect rate limits
            fetch_all_posts(next_url, new_acc)
          else
            {:ok, new_acc}
          end

        {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
          {:error, "Reddit API returned status #{status}: #{body}"}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "HTTP request failed: #{reason}"}
      end
    else
      err -> err
    end
  end

  def comments_for_post(permalink) do
    with {:ok, headers} <- headers() do
      comments_url = "#{@oauth_url}#{permalink}.json"
      case HTTPoison.get(comments_url, headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, [_, comments_listing]} = Jason.decode(body)
          # todo: this needs to paginate through the comments if there are more than 1000
          comments =
            get_in(comments_listing, ["data", "children"])
            |> Enum.map(& &1["data"])
            |> Enum.filter(fn item -> is_map(item) && Map.has_key?(item, "body") end)

          {:ok, comments}

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.puts("  -> Error fetching comments for #{permalink}: #{reason}")
          {:error, reason}
      end
    else
      err -> err
    end
  end

  # --- Helpers ---

  defp calculate_timestamp_range(date) do
    start_of_day = Timex.to_datetime(date, "Etc/UTC")
    end_of_day = Timex.end_of_day(start_of_day)
    {Timex.to_unix(start_of_day), Timex.to_unix(end_of_day)}
  end

  defp headers() do
    with {:ok, token} <- TokenManager.get_token() do
      {:ok,
       [
         {"Authorization", "Bearer #{token}"},
         {"User-Agent", "Elixir:Enkiro.App:v0.1 (by /u/your_reddit_username)"}
       ]}
    end
  end
end
