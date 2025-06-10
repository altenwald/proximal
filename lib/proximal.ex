defprotocol Proximal do
  @moduledoc """
  Proximal protocol is containing the function `to_xmlel/1` which is important
  to transform a data structure into the `Xmlel` structure from Saxy.
  """

  @doc """
  Transforms a data structure to Xmlel structure.
  """
  def to_xmlel(data)
end

defimpl Proximal, for: BitString do
  @moduledoc """
  Converts a string, presumably including a XML document, to Xmlel
  struct format.

  Examples:
      iex> Proximal.to_xmlel("<data/>")
      %Proximal.Xmlel{full_name: "data", attrs: %{}, children: [], name: "data"}
  """

  @doc """
  Convert a string into a `Xmlel` data structure.
  """
  def to_xmlel(data) do
    data
    |> Proximal.Xmlel.parse()
    |> Proximal.Xmlel.clean_spaces()
  end
end
