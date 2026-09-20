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

# web-fetch is a first-party MCP tool (not a shell command), so it is not
# subject to the interactive shell-permission gate that blocked bash curl in
# the first attempt of this demo. It still goes through the AWF sandbox.
tools:
  web-fetch:

# Containment: only GitHub domains are reachable from the agent sandbox.
# pypi.org is not a GitHub domain and is not the python ecosystem, so it is
# not on this allowlist. The second fetch below is expected to be blocked
# by the AWF firewall before it ever leaves the sandbox.
network:
  allowed: [github]

# No repository writes of any kind, including the create-issue fallback that
# gh-aw enables automatically when safe-outputs is omitted entirely.
safe-outputs: {}

timeout-minutes: 10
max-ai-credits: 30
---

# Network Firewall Demo

Use your web-fetch tool to fetch exactly these two URLs, in this order.
Do not skip either one. Do not just describe what you would do — actually
call the tool for both. Do not fetch anything else.

1. `https://api.github.com`
2. `https://pypi.org/simple/`

After fetching both, report, in plain text:

- Whether fetch 1 (api.github.com) returned content or an error, and what the
  error text (if any) was.
- Whether fetch 2 (pypi.org) returned content or an error, and what the error
  text (if any) was.

Do not change files, branches, labels, or repository settings. Do not attempt
any other network request.
