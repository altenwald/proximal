defmodule Proximal.Rpc do
  @moduledoc """
  XML-RPC let us to create method calls and responses. It works in both
  directions, encoding/decoding requests and encoding/decoding responses.
  """
  alias Proximal.Xmlel

  @doc """
  Encode a response. Providing a data, it's generating the XML-RPC valid
  response.

  Example:

      iex> Proximal.Rpc.encode_response(100)
      iex> |> to_string()
      "<methodResponse><params><param><value><int>100</int></value></param></params></methodResponse>"

      iex> Proximal.Rpc.encode_response(<<0, 0, 0>>)
      iex> |> to_string()
      "<methodResponse><params><param><value><base64>AAAA</base64></value></param></params></methodResponse>"

      iex> Proximal.Rpc.encode_response(nil)
      iex> |> to_string()
      "<methodResponse><params><param><value><nil/></value></param></params></methodResponse>"

      iex> Proximal.Rpc.encode_response(10.5)
      iex> |> to_string()
      "<methodResponse><params><param><value><double>10.5</double></value></param></params></methodResponse>"

      iex> Proximal.Rpc.encode_response(DateTime.new!(~D[2019-03-31], ~T[02:30:00]))
      iex> |> to_string()
      "<methodResponse><params><param><value><dateTime.iso8601>2019-03-31T02:30:00Z</dateTime.iso8601></value></param></params></methodResponse>"

      iex> Proximal.Rpc.encode_response(NaiveDateTime.new!(~D[2019-03-31], ~T[02:30:00]))
      iex> |> to_string()
      "<methodResponse><params><param><value><dateTime.iso8601>2019-03-31T02:30:00Z</dateTime.iso8601></value></param></params></methodResponse>"

      iex> Proximal.Rpc.encode_response(%{"name" => "Manuel"})
      iex> |> to_string()
      "<methodResponse><params><param><value><struct><member><name>name</name><value><string>Manuel</string></value></member></struct></value></param></params></methodResponse>"

      iex> Proximal.Rpc.encode_response([true, false, 10])
      iex> |> to_string()
      "<methodResponse><params><param><value><array><data><value><boolean>1</boolean></value><value><boolean>0</boolean></value><value><int>10</int></value></data></array></value></param></params></methodResponse>"
  """
  def encode_response(data) do
    Xmlel.new("methodResponse", %{}, [
      encode_params(data)
    ])
  end

  def encode_params(data) do
    Xmlel.new("params", %{}, [
      Xmlel.new("param", %{}, [
        Xmlel.new("value", %{}, [encode_value(data)])
      ])
    ])
  end

  def encode_value(%DateTime{} = datetime) do
    Xmlel.new("dateTime.iso8601", %{}, [DateTime.to_iso8601(datetime)])
  end

  def encode_value(%NaiveDateTime{} = datetime) do
    Xmlel.new("dateTime.iso8601", %{}, [NaiveDateTime.to_iso8601(datetime) <> "Z"])
  end

  def encode_value(%{} = data) do
    members =
      for {name, value} <- data do
        Xmlel.new("member", %{}, [
          Xmlel.new("name", %{}, [name]),
          Xmlel.new("value", %{}, [encode_value(value)])
        ])
      end

    Xmlel.new("struct", %{}, members)
  end

  def encode_value(values) when is_list(values) do
    values = for value <- values, do: Xmlel.new("value", %{}, [encode_value(value)])

    Xmlel.new("array", %{}, [
      Xmlel.new("data", %{}, values)
    ])
  end

  def encode_value(binary) when is_binary(binary) do
    if String.printable?(binary) do
      Xmlel.new("string", %{}, [binary])
    else
      Xmlel.new("base64", %{}, [Base.encode64(binary)])
    end
  end

  def encode_value(true), do: Xmlel.new("boolean", %{}, ["1"])
  def encode_value(false), do: Xmlel.new("boolean", %{}, ["0"])

  def encode_value(double) when is_float(double) do
    Xmlel.new("double", %{}, [to_string(double)])
  end

  def encode_value(integer) when is_integer(integer) do
    Xmlel.new("int", %{}, [to_string(integer)])
  end

  def encode_value(nil), do: Xmlel.new("nil")

  @doc """
  Decode a response from RPC. This performs the complementary of
  `encode_response/1`.

  Examples:
      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value>Manuel</value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", ["Manuel"]}

      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value><int>100</int></value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", [100]}

      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value><base64>AAAA</base64></value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", [<<0, 0, 0>>]}

      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value><nil/></value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", [nil]}

      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value><double>10.5</double></value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", [10.5]}

      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value><dateTime.iso8601>2019-03-31T02:30:00Z</dateTime.iso8601></value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", [~N[2019-03-31 02:30:00]]}

      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value><dateTime.iso8601>2019-03-31T02:30:00Z</dateTime.iso8601></value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", [~N[2019-03-31 02:30:00]]}

      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value><struct><member><name>name</name><value><string>Manuel</string></value></member></struct></value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", [%{"name" => "Manuel"}]}

      iex> import Proximal.Xmlel, only: [sigil_x: 2]
      iex> ~x[<methodCall><methodName>io_puts</methodName><params><param><value><array><data><value><boolean>1</boolean></value><value><boolean>0</boolean></value><value><int>10</int></value></data></array></value></param></params></methodCall><methodName>io_puts</methodName>]
      iex> |> Proximal.Rpc.decode_request()
      {"io_puts", [[true, false, 10]]}
  """
  def decode_request(%Xmlel{name: "methodCall"} = request) do
    with [%Xmlel{name: "methodName", children: [method_name]} | _] <- request["methodName"],
         [params | _] <- request["params"] do
      {method_name, decode_params(params)}
    else
      nil -> nil
    end
  end

  @doc """
  Decode params passed to the RPC system. It's performing the opposite as
  `encode_params/1` does.
  """
  def decode_params(%Xmlel{name: "params"} = params) do
    for %Xmlel{name: "param", children: [%Xmlel{name: "value", children: [value]}]} <-
          params["param"] do
      decode_value(value)
    end
  end

  def decode_value(%Xmlel{name: name, children: values}) do
    decode_value(name, values)
  end

  def decode_value(value) when is_binary(value), do: value

  defp decode_value(name, [int_val]) when name in ["i4", "int"] do
    {value, ""} = Integer.parse(int_val)
    value
  end

  defp decode_value("double", [float_val]) do
    {value, ""} = Float.parse(float_val)
    value
  end

  defp decode_value("string", [string_val]), do: string_val
  defp decode_value("base64", [base64_val]), do: Base.decode64!(base64_val)
  defp decode_value("boolean", ["1"]), do: true
  defp decode_value("boolean", ["0"]), do: false

  defp decode_value("dateTime.iso8601", [datetime_val]) do
    NaiveDateTime.from_iso8601!(datetime_val)
  end

  defp decode_value("array", [data]) do
    for %Xmlel{children: values} <- data["value"] do
      [value] = for(value <- values, do: decode_value(value))
      value
    end
  end

  defp decode_value("struct", members) do
    for %Xmlel{name: "member"} = member <- members do
      [%Xmlel{name: "name", children: [key]}] = member["name"]
      [%Xmlel{name: "value", children: [value]}] = member["value"]
      val = decode_value(value)
      {key, val}
    end
    |> Map.new()
  end

  defp decode_value("nil", []), do: nil
end
