defmodule Enkiro.Utils.Reddit.SavePostsWorker do
  use Oban.Worker,
    queue: :ingest,
    max_attempts: 3

  alias ExAws.S3

  @bucket_name "enkiro"

  def perform(%Oban.Job{args: %{"post_file_path" => post_file_path}}) do
    {_pid, local_path} = Temp.open!()

    @bucket_name
    |> S3.download_file(post_file_path, local_path)
    |> ExAws.request!

    local_path
    |> File.stream!()
    |> Stream.map(&Jason.decode!/1)
    |> Stream.each(fn post ->
      save_post(post)
    end)
    |> Stream.run()
  end

  defp save_post(post_data) do
    IO.inspect([
      post_data["title"],
      post_data["author"],
      post_data["body"],
      post_data["url"],
      post_data["id"],
      Timex.from_unix(post_data["posted_at"]),
      post_data["permalink"],
      post_data["comment_count"],
      post_data["score"],
      post_data["upvote_ratio"],
      post_data["is_video"],
      post_data["is_text_post"],
      post_data["flair"],
      post_data["thumbnail_url"],
      # post_data["raw_data"]
    ])
  end
end
