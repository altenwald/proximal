defmodule Proximal.Document do
  alias Proximal.Xmlel

  @callback render(map()) :: Xmlel.t()

  defmacro __using__(_) do
    quote do
      @behaviour Proximal.Document
      defimpl Saxy.Builder, for: __MODULE__ do
        @moduledoc false
        def build(%module{} = data) do
          data
          |> module.render()
          |> Proximal.Xmlel.encode()
        end
      end
    end
  end
end
