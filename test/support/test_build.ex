defmodule TestBuild do
  use Proximal.Document

  defstruct name: nil

  def render(data), do: Proximal.Xmlel.new(data.name, %{}, [])
end
