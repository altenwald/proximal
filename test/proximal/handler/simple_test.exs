defmodule Proximal.Handler.SimpleTest do
  use ExUnit.Case, async: false
  alias Proximal.Xmlel

  describe "parsing" do
    test "parse simple document" do
      document = "<root><child1/></root>"
      result = Saxy.parse_string(document, Proximal.Handler.Simple, [])
      assert {:halt, [%Xmlel{name: "root", children: [%Xmlel{name: "child1"}]}], ""} == result
    end
  end
end
