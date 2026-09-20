---
description: Demonstrate the AWF network egress firewall blocking a disallowed domain, live.
on:
  workflow_dispatch:
  roles: [admin, maintainer, write]

# Same containment shape as repo-status.md: every repository permission is
# read. copilot-requests is not a repository permission; it authorizes
# Copilot inference through the Actions token, which is what pays for the
# model call.
permissions:
  contents: read
  issues: read
  pull-requests: read
  actions: read
  copilot-requests: write

engine:
  id: copilot

# Only curl, and only for this demo's two fixed commands. Nothing else needed.
tools:
  bash: ["curl"]

# Containment: only GitHub domains are reachable from the agent sandbox.
# pypi.org is not a GitHub domain and is not the python ecosystem, so it is
# not on this allowlist. The second command below is expected to be blocked
# by the AWF firewall before it ever leaves the sandbox.
network:
  allowed: [github]

timeout-minutes: 10
max-ai-credits: 30
---

# Network Firewall Demo

Run exactly these two shell commands, in this order, using your bash tool.
Do not skip either one. Do not summarize instead of running them. Do not run
anything else.

1. `curl -sS -m 8 -o /dev/null -w "HTTP_STATUS:%{http_code}\n" https://api.github.com`
2. `curl -sS -m 8 -o /dev/null -w "HTTP_STATUS:%{http_code}\n" https://pypi.org/simple/`

After running both commands, report, in plain text:

- The exact output (including any error text) of command 1.
- The exact output (including any error text) of command 2.
- One sentence stating whether each command succeeded or failed.

Do not change files, branches, labels, or repository settings. Do not attempt
any other network request.
