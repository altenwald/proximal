defmodule Proximal.Stream do
  @moduledoc """
  Process a stream chunk by chunk to obtain XML documents or stanzas continuously.
  The stream is initiated passing a PID where the parsed elements from the chunks
  are going to be sent.

  The parser converts the stream data into `%Proximal.Xmlel{}` structs and
  sends them back to the specified process.
  """

  alias Proximal.Partial

  @handler Proximal.Handler.Sender

  @doc """
  Creates a new `Proximal.Partial` struct to parse the incoming stream
  continuously. Events are sent back to `pid`, which defaults to `self()`.
  """
  def new(pid \\ self()) do
    {:ok, partial} = Partial.new(@handler, pid, continuous: true)
    partial
  end

  @doc """
  Sends a chunk of XML data to the stream parser.
  """
  def parse({:cont, partial}, chunk), do: Partial.parse(partial, chunk)

  def parse({:halt, pid, rest}, chunk) do
    pid
    |> new()
    |> Partial.parse(rest <> chunk)
  end

  def parse({:error, _} = error, _chunk), do: error

  def parse(partial, chunk) do
    Partial.parse(partial, chunk)
  end

  @doc """
  Finalises the stream parser, ensuring any remaining state is closed cleanly.
  """
  def terminate({:cont, partial}) do
    with {:ok, _state} <- Partial.terminate(partial) do
      {:ok, ""}
    end
  end

  def terminate({:halt, _state, rest}) do
    {:ok, rest}
  end

  def terminate({:error, _} = error), do: error

  def terminate(%Partial{} = partial) do
    with {:ok, _state} <- Partial.terminate(partial) do
      {:ok, ""}
    end
  end
end
