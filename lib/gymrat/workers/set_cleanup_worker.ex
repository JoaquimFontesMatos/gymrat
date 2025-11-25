defmodule Gymrat.Workers.SetCleanupWorker do
  use Oban.Worker
  require Logger

  @impl Worker
  def perform(%Oban.Job{}) do
    case Gymrat.Training.Sets.smart_delete_old_sets() do
      {:ok, {:ok, count}} ->
        Logger.info("Set cleanup successful. Deleted #{count} old set records.")
        :ok

      {:error, reason} ->
        Logger.error("Set cleanup failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
