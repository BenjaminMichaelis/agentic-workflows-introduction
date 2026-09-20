---
description: Create a short repository status report for newcomers.
on:
  workflow_dispatch:
  roles: [admin, maintainer, write]

# Teaching moment: the agent's GitHub permissions stay read-only.
# The issue is created later by the create-issue safe output, not by giving
# the agent direct write access to the GitHub Issues API.
permissions:
  contents: read
  issues: read
  pull-requests: read
  actions: read

engine:
  id: copilot

tools:
  github:
    mode: gh-proxy

network:
  allowed: [github]

timeout-minutes: 10
max-ai-credits: 300

safe-outputs:
  create-issue:
    max: 1
---

# Repo Status

Create a concise repository status report for someone seeing this repository for the first time.

Look at the README, recent repository activity, open issues, open pull requests, and workflow files.

Use the `create-issue` safe output to open one issue titled `Repo status report`.

The issue body should include:

- what this repository is for
- what looks ready
- what might need attention
- one suggested next step

Do not change files, branches, labels, or repository settings.
