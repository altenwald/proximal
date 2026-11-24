%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/", "lib/proximal/parser/builder.ex"]
      }
    }
  ]
}
