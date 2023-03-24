defmodule Proximal.Handler.SimpleTest do
  use ExUnit.Case, async: false
  alias Proximal.Xmlel

  describe "parsing" do
    test "parse simple document" do
      document = "<root><child1/></root>"
      result = Saxy.parse_string(document, Proximal.Handler.Simple, [])

      assert {:halt,
              [
                %Xmlel{
                  full_name: "root",
                  name: "root",
                  children: [%Xmlel{full_name: "child1", name: "child1"}]
                }
              ], ""} == result
    end
  end
end
