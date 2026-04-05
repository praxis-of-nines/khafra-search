defmodule Khafra.Queue.ManageTableConsumer do
  use Lapin.Connection

  require Logger

  def handle_deliver(_channel, message) do
    case :erlang.binary_to_term(message.payload) do
      {:record_op, record, operation} ->
        operation.(record)

      {:record_op, operation} ->
        operation.()

      other ->
        Logger.debug(fn -> "Unhandled message: #{inspect(other)}" end)
    end

    :ok
  end
end
