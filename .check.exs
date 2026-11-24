[
  tools: [
    {:mix_audit,
     command: "mix deps.audit --ignore-advisory-ids GHSA-rhv4-8758-jx7v,GHSA-6c27-994x-c52f"},
    {:prisma, "mix prisma"}
  ]
]
