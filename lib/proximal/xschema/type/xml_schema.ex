defmodule Proximal.Xschema.Type.XMLSchema do
  ## TODO: @behaviour Proximal.Xschema.Type

  def id(), do: "http://www.w3.org/2001/XMLSchema"

  def is_valid_type?("string"), do: true
  def is_valid_type?("int"), do: true
  def is_valid_type?("double"), do: true
  def is_valid_type?(_), do: false

  def string(data, nil), do: is_binary(data)

  def int(data, nil), do: is_integer(data)

  def double(data, nil), do: is_float(data)
end
