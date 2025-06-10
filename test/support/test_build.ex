defmodule TestBuild do
  @moduledoc false
  use Proximal.Document

  defstruct name: nil

  @impl Proximal.Document
  def render(data), do: Proximal.Xmlel.new(data.name, %{}, [])
end
