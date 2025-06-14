defmodule Proximal.Handler.Sender do
  @moduledoc false

  @behaviour Saxy.Handler

  alias Proximal.Handler.Simple
  alias Proximal.Xmlel

  @type t() :: %__MODULE__{
          pid: pid() | nil,
          stack: [Xmlel.t()],
          debug_xml: boolean()
        }

  defstruct pid: nil, stack: [], debug_xml: false

  @impl Saxy.Handler
  def handle_event(:start_document, _prolog, pid) do
    debug_xml = Application.get_env(:proximal, :debug_xml, false)
    if debug_xml, do: send(pid, :xmlstartdoc)
    {:ok, %__MODULE__{pid: pid, debug_xml: debug_xml}}
  end

  def handle_event(:start_element, {tag_name, attributes}, data) do
    send(data.pid, {:xmlstreamstart, tag_name, attributes})
    {:ok, stack} = Simple.handle_event(:start_element, {tag_name, attributes}, data.stack)

    case stack do
      [%Xmlel{name: "stream", children: []}] ->
        {:halt, data.pid}

      _ ->
        {:ok, %__MODULE__{data | stack: stack}}
    end
  end

  def handle_event(:characters, chars, data) do
    if data.debug_xml, do: send(data.pid, {:xmlcdata, chars})
    {:ok, stack} = Simple.handle_event(:characters, chars, data.stack)
    {:ok, %__MODULE__{data | stack: stack}}
  end

  def handle_event(:end_element, tag_name, data) do
    if data.debug_xml, do: send(data.pid, {:xmlstreamend, tag_name})

    case Simple.handle_event(:end_element, tag_name, data.stack) do
      {:ok, stack} ->
        {:ok, %__MODULE__{data | stack: stack}}

      {:halt, [xmlel]} ->
        send(data.pid, {:xmlelement, xmlel})
        {:halt, data.pid}
    end
  end
end
