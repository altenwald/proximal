defmodule Proximal.Handler do
  @moduledoc """
  Behaviour for SAX-style XML event handlers used by `Proximal.Parser` and `Proximal.Partial`.
  """

  @type event_type() ::
          :start_document
          | :end_document
          | :start_element
          | :end_element
          | :characters
          | :cdata

  @type event_data() :: term()
  @type state() :: term()

  @callback handle_event(event_type(), event_data(), state()) ::
              {:ok, state()}
              | {:stop, state()}
              | {:halt, state()}
              | {:error, term()}
end
