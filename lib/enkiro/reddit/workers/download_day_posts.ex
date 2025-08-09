defmodule Enkiro.Reddit.Workers.DownloadDayPosts do
  use Oban.Worker,
    queue: :ingest,
    max_attempts: 3

  alias Enkiro.Utils.Reddit.Fetcher
  alias ExAws.S3

  def perform(%Oban.Job{args: %{"subreddit" => subreddit, "date" => date}}) do
    date = Timex.parse!(date, "{YYYY}-{M}-{D}")
    # we need to mock this in the tests
    case Fetcher.fetch_posts_for_day(subreddit, date) do
      {:ok, posts} ->
        case Temp.open() do
          {:ok, _fd, path} ->
            {:ok, fd} = File.open(path, [:append, :utf8])
            Enum.each(posts, fn post ->
              IO.write(fd, "#{Jason.encode!(post)}")
            end)

            File.close(fd)

            remote_file_path = "reddit/#{subreddit}/#{Date.to_iso8601(date)}.jsonl"

            path
            |> S3.Upload.stream_file
            |> S3.upload("enkiro", remote_file_path)
            |> ExAws.request!

            %{subreddit: subreddit, remote_file_path: remote_file_path}
            |> Enkiro.Utils.Reddit.CommentWorker.new()
            |> Oban.insert()

            {:ok, path}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
