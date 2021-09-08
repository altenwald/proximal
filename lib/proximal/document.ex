defmodule Proximal.Document do
  @moduledoc """
  When you need to implement a parser for a structure, you could add the
  following code:

  ```elixir
  defmodule MyStruct do
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
  ```

  The code should let you to create your data in the way you need and
  thanks to the implementation of the `render/1` function, you could use:

  ```elixir
  %MyStruct{name: "Manuel", surname: "Rubio"}
  |> Proximal.to_xmlel()
  ```

  To get the representation in `%Xmlel{}` structs and even adding at the
  end of that pipe `to_string/1` to get the XML in a string.
  """
  alias Proximal.Xmlel

  @callback render(struct()) :: Xmlel.t()

  defmacro __using__(_) do
    quote do
      @behaviour Proximal.Document
      defimpl Proximal, for: __MODULE__ do
        @moduledoc false
        def to_xmlel(%module{} = data) do
          module.render(data)
        end
      end
    end
  end
end
