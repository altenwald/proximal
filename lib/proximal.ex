defprotocol Proximal do
  @doc """
  Transforms a data structure to Xmlel structure.
  """
  def to_xmlel(data)
end

defimpl Proximal, for: BitString do
  @moduledoc """
  Converts a string, presumibly including a XML document, to Xmlel
  struct format.

  Examples:
      iex> Proximal.to_xmlel("<data/>")
      %Proximal.Xmlel{attrs: %{}, children: [], name: "data"}
  """
  def to_xmlel(data) do
    data
    |> Proximal.Xmlel.parse()
    |> Proximal.Xmlel.clean_spaces()
  end
end
