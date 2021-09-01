defmodule Proximal.Stream do
  @moduledoc """
  Process a stream chunk by chunk to obtain a XML document.
  The stream is initiated passing a PID where the information
  from the chunks are going to be received.

  The parser is using `Proximal.Handler.Sender` which is
  responsible to convert the stream data into a valid `%Xmlel{}`
  and send it back to the specified process.
  """

  alias Saxy.Partial

  @handler Proximal.Handler.Sender

  @doc """
  Creates a new `Saxy.Partial` struct to parser little by little
  the incoming stream. The information is sent back to the `pid`
  passed as a paramter, by default this is set as `self()`.
  """
  def new(pid \\ self()) do
    {:ok, partial} = Partial.new(@handler, pid)
    partial
  end

  @doc """
  Use it to send every chunk of the XML document(s) we want to
  parse. Every `chunk` will be sent back to the process passed
  initially in the new function through the `partial` parameter.
  """
  def parse({:cont, partial}, chunk), do: parse(partial, chunk)

  def parse({:halt, pid, rest}, chunk) do
    pid
    |> new()
    |> parse(rest <> chunk)
  end

  def parse(partial, chunk) do
    Partial.parse(partial, chunk)
  end

  @doc """
  When we wants to send the rest of the XML document(s) we
  have to use this function which let us to finalise the
  `partial` data.

  Note that because a change into the Saxy 1.4, everytime we
  terminate a ending document, it will be in the `:halt` state,
  otherwise it will generate a parsing error.
  """
  def terminate({:halt, _state, rest}) do
    {:ok, rest}
  end
end
