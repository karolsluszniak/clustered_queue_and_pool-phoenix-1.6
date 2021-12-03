enabled_tools = [
  {:compiler, env: %{"MIX_ENV" => "test"}},
  {:ex_unit, true},
  {:formatter, true},
  {:unused_deps, true}
]

disabled_tools = Enum.map(~w[credo dialyzer doctor ex_doc sobelow]a, &{&1, false})

[
  tools: enabled_tools ++ disabled_tools
]
