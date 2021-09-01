defmodule Proximal.Xschema.Type.SoapEncoding do
  def id(), do: "http://schemas.xmlsoap.org/soap/encoding/"

  def is_valid_type?("Array"), do: true
  def is_valid_type?(_), do: false

  def array(data, %{"ref" => [ns, type]} = attrs) do
    is_list(data) and Enum.all?(data, &apply(ns, type, [&1, attrs]))
  end
end
