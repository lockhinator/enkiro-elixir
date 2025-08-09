# lib/reddit_fetcher.ex

defmodule Enkiro.Utils.Reddit.Fetcher do
  @moduledoc """
  A module to fetch all posts and their comments from a given subreddit for a specific day
  using authenticated Reddit API requests.
  """

  # Add these dependencies to your mix.exs:
  # {:httpoison, "~> 2.0"},
  # {:jason, "~> 1.4"},
  # {:timex, "~> 3.7"},
  # {:oauth2, "~> 2.0"}
  alias Enkiro.Utils.Reddit.TokenManager

  @oauth_url "https://oauth.reddit.com"

  # --- Public API ---

  @doc """
  Fetches all posts and their comments for a given subreddit and date.

  ## Parameters
    - subreddit (String.t): The name of the subreddit (e.g., "elixir").
    - date (Date.t): The specific date to fetch posts from.

  ## Returns
    - `{:ok, posts}`: A list of posts, where each post is a map containing its
      details and a list of its comments.
    - `{:error, reason}`: An error tuple.
  """
  def fetch_subreddit_data_for_day(subreddit, date) do
    IO.puts("Fetching data for r/#{subreddit} on #{Date.to_iso8601(date)}...")

    {start_timestamp, end_timestamp} = calculate_timestamp_range(date)
    search_url =
      "#{@oauth_url}/r/#{subreddit}/top.json?q=timestamp:#{start_timestamp}..#{end_timestamp}&restrict_sr=on&sort=new&syntax=cloudsearch&limit=1"

    IO.inspect(search_url, label: "Search URL")

    with {:ok, posts} <- fetch_all_posts(search_url) do
      IO.puts("Found #{Enum.count(posts)} posts. Now fetching comments for each...")

      processed_posts =
        posts
        |> Task.async_stream(&fetch_comments_for_post/1, timeout: 90_000)
        |> Enum.map(fn {:ok, result} -> result end)

      {:ok, processed_posts}
    end
  end

  def fetch_posts_for_day(subreddit, date) do
    {start_timestamp, end_timestamp} = calculate_timestamp_range(date)
    search_url =
      "#{@oauth_url}/r/#{subreddit}/top.json?q=timestamp:#{start_timestamp}..#{end_timestamp}&restrict_sr=on&sort=new&syntax=cloudsearch&limit=1"
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

  defp fetch_comments_for_post(post_data) do
    with {:ok, headers} <- headers() do
      permalink = post_data["permalink"]
      comments_url = "#{@oauth_url}#{permalink}.json"

      IO.puts("  -> Fetching comments for: #{post_data["title"]}")

      case HTTPoison.get(comments_url, headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          File.write("reddit_comments_data_#{post_data["id"]}.json", body)
          {:ok, [_, comments_listing]} = Jason.decode(body)
          comments =
            get_in(comments_listing, ["data", "children"])
            |> Enum.map(& &1["data"])
            |> Enum.filter(fn item -> is_map(item) && Map.has_key?(item, "body") end)

          {:ok, Map.put(post_data, "comments", comments)}

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.puts("  -> Error fetching comments for #{permalink}: #{reason}")
          {:ok, Map.put(post_data, "comments", [])}
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
