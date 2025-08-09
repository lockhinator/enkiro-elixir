defmodule Enkiro.Utils.Reddit.CommentWorker do
  use Oban.Worker,
    queue: :ingest,
    max_attempts: 3

  #alias ExAws.S3

  def perform(%Oban.Job{args: %{"subreddit" => _subreddit, "remote_file_path" => _remote_file_path}}) do
      #remote_file_path
      #|> S3.Download.stream!()
      #|> Stream.map(&Jason.decode!/1)
      #|> Stream.each(fn post ->

      #end)
  end
end
