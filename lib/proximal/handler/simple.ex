defmodule Proximal.Handler.Simple do
  @moduledoc false

  @behaviour Saxy.Handler

  alias Proximal.Xmlel

  @impl Saxy.Handler
  def handle_event(:start_document, _prolog, _state) do
    {:ok, []}
  end

  def handle_event(:start_element, {tag_name, attributes}, stack) do
    tag = Xmlel.new(tag_name, attributes)
    {:ok, [tag | stack]}
  end

  def handle_event(:characters, chars, [%Xmlel{children: content} = xmlel | stack]) do
    current = %Xmlel{xmlel | children: [chars | content]}
    {:ok, [current | stack]}
  end

  def handle_event(:end_element, tag_name, [%Xmlel{full_name: tag_name} = xmlel | stack]) do
    current = %Xmlel{xmlel | children: Enum.reverse(xmlel.children)}

    case stack do
      [] ->
        {:halt, [current]}

      [%Xmlel{children: parent_content} = parent | rest] ->
        parent = %Xmlel{parent | children: [current | parent_content]}
        {:ok, [parent | rest]}
    end
  end
end
