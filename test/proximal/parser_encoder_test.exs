defmodule Proximal.ParserEncoderTest do
  use ExUnit.Case, async: true

  alias Proximal.ParseError
  alias Proximal.Parser
  alias Proximal.Prolog
  alias Proximal.Stream, as: XmlStream
  alias Proximal.Xmlel

  describe "parser edge cases" do
    test "parses prolog, comments, processing instructions, and CDATA" do
      xml = """
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <!-- leading comment -->
      <?target instruction?>
      <root attr="a &amp; b &#65; &#x42;">
        <!-- inner comment -->
        <![CDATA[<raw & unescaped>]]>
        <child/>
      </root>
      """

      {xmlel, rest} = Xmlel.parse(xml)
      assert String.trim(rest) == ""
      assert xmlel.name == "root"
      assert xmlel.attrs == %{"attr" => "a & b A B"}
      assert Enum.any?(xmlel.children, &(&1 == "<raw & unescaped>"))
      assert Enum.any?(xmlel.children, &match?(%Xmlel{name: "child"}, &1))
    end

    test "parses UTF-8 names and values" do
      xml = "<café sabor=\"dulce &amp; fuerte\">¡Hola España! 🚀</café>"
      {xmlel, ""} = Xmlel.parse(xml)

      assert xmlel.name == "café"
      assert xmlel.attrs == %{"sabor" => "dulce & fuerte"}
      assert xmlel.children == ["¡Hola España! 🚀"]
    end

    test "parses namespaces and prefixed attributes" do
      xml = ~s(<ns:root xmlns:ns="urn:example" ns:id="42" plain="ok"/>)
      {xmlel, ""} = Xmlel.parse(xml)

      assert xmlel.schema == "ns"
      assert xmlel.name == "root"
      assert xmlel.full_name == "ns:root"
      assert xmlel.namespaces == %{"ns" => "urn:example"}
      assert xmlel.attrs == %{{"ns", "id"} => "42", "plain" => "ok"}
    end

    test "returns ParseError on malformed XML" do
      assert {:error, %ParseError{reason: {:wrong_closing_tag, "foo", "bar"}}} =
               Parser.parse_string("<foo></bar>", Proximal.Handler.Simple, [])

      assert {:error, %ParseError{reason: {:invalid_encoding, "ISO-8859-1"}}} =
               Parser.parse_string(
                 ~s(<?xml version="1.0" encoding="ISO-8859-1"?><foo/>),
                 Proximal.Handler.Simple,
                 []
               )

      assert {:error, %ParseError{reason: {:invalid_pi, "xml"}}} =
               Parser.parse_string("<foo><?xml?></foo>", Proximal.Handler.Simple, [])
    end

    test "ParseError.message/1 formats all error reasons" do
      assert Exception.message(%ParseError{reason: {:token, :lt}, binary: "<", position: 1}) ==
               "unexpected end of input, expected token: :lt"

      assert Exception.message(%ParseError{reason: {:token, :eq}, binary: "<a b>", position: 4}) ==
               "unexpected byte \">\", expected token: :eq"

      assert Exception.message(%ParseError{reason: {:wrong_closing_tag, "a", "b"}}) ==
               "unexpected ending tag \"b\", expected tag: \"a\""

      assert Exception.message(%ParseError{reason: {:invalid_pi, "xml"}}) =~
               "unexpected target name \"xml\""

      assert Exception.message(%ParseError{reason: {:invalid_encoding, "latin1"}}) =~
               "unexpected encoding declaration \"latin1\""

      assert Exception.message(%ParseError{reason: {:bad_return, {:start_element, :bad}}}) =~
               "unexpected return :bad in :start_element event handler"
    end

    test "supports entity expansion modes and custom handler returns" do
      xml = ~s(<root a="&amp; &unknown;">&lt; &custom; &#x1F680;</root>)

      defmodule EntityMod do
        def expand("unknown"), do: "[UNK]"
        def expand("custom"), do: "[CUST]"
      end

      assert {:halt, [el_never], ""} =
               Parser.parse_string(xml, Proximal.Handler.Simple, [], expand_entity: :never)

      assert el_never.attrs == %{"a" => "&amp; &unknown;"}
      assert el_never.children == ["&lt; &custom; 🚀"]

      assert {:halt, [el_skip], ""} =
               Parser.parse_string(xml, Proximal.Handler.Simple, [], expand_entity: :skip)

      assert el_skip.attrs == %{"a" => "& "}
      assert el_skip.children == ["<  🚀"]

      assert {:halt, [el_mfa], ""} =
               Parser.parse_string(xml, Proximal.Handler.Simple, [],
                 expand_entity: {EntityMod, :expand, []}
               )

      assert el_mfa.attrs == %{"a" => "& [UNK]"}
      assert el_mfa.children == ["< [CUST] 🚀"]

      defmodule BadHandler do
        @behaviour Proximal.Handler
        def handle_event(_event, _data, _state), do: :unexpected
      end

      assert {:error, %ParseError{reason: {:bad_return, {:start_document, :unexpected}}}} =
               Parser.parse_string("<a/>", BadHandler, [])

      defmodule OkHandler do
        @behaviour Proximal.Handler
        def handle_event(:end_document, _, state), do: {:ok, [:done | state]}
        def handle_event(_event, _data, state), do: {:ok, state}
      end

      assert {:ok, [:done]} = Parser.parse_string("<a/>", OkHandler, [])
    end
  end

  describe "encoder and to_iodata" do
    test "encodes directly to iodata without intermediate tuples" do
      xmlel =
        Xmlel.new(
          "ns:root",
          %{"xmlns:ns" => "urn:example&1", "ns:k" => ~s(a"b'c), "x" => "<1>"},
          ["hello & <world>", Xmlel.new("empty")]
        )

      iodata = Xmlel.to_iodata(xmlel)
      assert is_list(iodata)

      xml = IO.iodata_to_binary(iodata)

      assert String.starts_with?(xml, "<ns:root ")
      assert String.contains?(xml, ~s(xmlns:ns="urn:example&amp;1"))
      assert String.contains?(xml, ~s(x="&lt;1&gt;"))
      assert String.contains?(xml, ~s(ns:k="a&quot;b&apos;c"))
      assert String.ends_with?(xml, ">hello &amp; &lt;world&gt;<empty/></ns:root>")
      assert {^xmlel, ""} = Xmlel.parse(xml)

      assert to_string(xmlel) == xml
    end

    test "encodes with prolog keyword list or struct" do
      xmlel = Xmlel.new("doc", %{}, ["ok"])

      assert Xmlel.to_iodata(xmlel, version: "1.0", encoding: :utf8, standalone: true)
             |> IO.iodata_to_binary() ==
               ~s(<?xml version="1.0" encoding="utf-8" standalone="yes"?><doc>ok</doc>)

      prolog = %Prolog{version: "1.0", encoding: "UTF-8", standalone: false}

      assert Xmlel.to_iodata(xmlel, prolog) |> IO.iodata_to_binary() ==
               ~s(<?xml version="1.0" encoding="UTF-8" standalone="no"?><doc>ok</doc>)
    end

    test "encodes structs implementing Proximal protocol directly and as children" do
      child = %TestBuild{name: "inner"}
      root = Xmlel.new("outer", %{}, [child])

      assert Xmlel.to_iodata(child) |> IO.iodata_to_binary() == "<inner/>"
      assert Xmlel.to_iodata(root) |> IO.iodata_to_binary() == "<outer><inner/></outer>"
    end
  end

  describe "continuous streaming" do
    test "streams multiple root stanzas split at arbitrary byte boundaries" do
      Application.put_env(:proximal, :debug_xml, false)
      payload = "<a>1</a><!-- gap --><b attr=\"x &amp; y\">café</b><c/>"

      partial =
        payload
        |> String.graphemes()
        |> Enum.reduce(XmlStream.new(), fn chunk, acc ->
          assert {:cont, next} = XmlStream.parse(acc, chunk)
          next
        end)

      assert {:ok, ""} = XmlStream.terminate(partial)

      assert_received {:xmlelement, %Xmlel{name: "a", children: ["1"]}}

      assert_received {:xmlelement,
                       %Xmlel{name: "b", attrs: %{"attr" => "x & y"}, children: ["café"]}}

      assert_received {:xmlelement, %Xmlel{name: "c", children: []}}
    end

    test "handles stream errors, terminate variants, and Partial helpers" do
      err = XmlStream.new() |> XmlStream.parse("<foo><bar></foo>")
      assert {:error, %ParseError{}} = XmlStream.parse(err, "<baz/>")
      assert {:error, %ParseError{}} = XmlStream.terminate(err)

      assert {:error, %ParseError{reason: {:token, :lt}}} =
               XmlStream.new() |> XmlStream.terminate()

      {:cont, partial_ready} = XmlStream.new() |> XmlStream.parse("<a/>")
      assert {:ok, ""} = XmlStream.terminate(partial_ready)
      assert {:ok, "rest"} = XmlStream.terminate({:halt, self(), "rest"})

      {:ok, partial} = Proximal.Partial.new(Proximal.Handler.Simple, [])
      assert [] == Proximal.Partial.get_state(partial)

      assert {:halt, [%Xmlel{name: "x"}], ""} =
               Proximal.Partial.parse(partial, "<x/>", [:ignored])
    end
  end
end
