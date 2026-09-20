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

# No restricted bash allowlist here on purpose: an earlier version of this
# workflow set tools.bash to an explicit ["curl"] list, and curl specifically
# was refused by the Copilot CLI's interactive shell-permission gate ("Permission
# denied and could not request permission from user") in --no-ask-user mode,
# BEFORE the request ever reached the AWF firewall. That gate is a sandbox
# policy layer that sits in front of the firewall, not the firewall itself,
# and it happens to treat curl more strictly than plain `python3`. Leaving
# tools.bash unset keeps the default unrestricted shell, under which python3
# is not blocked by that gate and the request reaches the real AWF proxy.
tools: {}

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

Run exactly this Python one-liner via your shell/bash tool, once for each URL
below, in order. Do not use curl (curl is blocked by an unrelated sandbox
permission policy, not by the firewall this demo is about). Do not skip
either URL. Do not just describe what you would do — actually run the
command for both.

```
python3 -c "import urllib.request,sys; r=urllib.request.urlopen('URL', timeout=10); print('SUCCESS', r.status)"
```

1. Replace `URL` with `https://api.github.com` and run it.
2. Replace `URL` with `https://pypi.org/simple/` and run it.

If a command errors, capture the exact error text/exception message printed —
do not paraphrase it.

After running both, report, in plain text:

- Whether fetch 1 (api.github.com) printed `SUCCESS` or an error, and the
  exact error text (if any).
- Whether fetch 2 (pypi.org) printed `SUCCESS` or an error, and the exact
  error text (if any).

Do not change files, branches, labels, or repository settings. Do not attempt
any other network request.

Report your two-line summary using the `noop` safe-output tool only. Do NOT
call `create_issue` — this is a live demo and must not leave a GitHub issue
behind.
