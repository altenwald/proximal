defmodule MyStruct do
  @moduledoc false
  use Proximal.Document
  alias Proximal.Xmlel

  defstruct [:name, :surname]

  @impl Proximal.Document
  def render(%__MODULE__{name: name, surname: surname}) do
    Xmlel.new("mystruct", %{}, [
      Xmlel.new("name", %{}, [name]),
      Xmlel.new("surname", %{}, [surname])
    ])
  end
end
