defmodule Proximal.DocumentTest do
  use ExUnit.Case, async: false
  import Proximal.Xmlel, only: [sigil_x: 2]

  describe "custom documents" do
    test "mystruct" do
      mystruct = %MyStruct{name: "Manuel", surname: "Rubio"}
      document = "<mystruct><name>Manuel</name><surname>Rubio</surname></mystruct>"
      assert ~x[#{document}] == Proximal.to_xmlel(mystruct)
      assert document == to_string(Proximal.to_xmlel(mystruct))
    end
  end
end
