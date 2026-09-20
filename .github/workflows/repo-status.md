---
description: Create a short repository status report for newcomers.
on:
  workflow_dispatch:
  roles: [admin, maintainer, write]

# Teaching moment: every repository permission below is read. Nothing here
# lets the agent write to the repo. The issue still gets created, by the
# create-issue safe output running in a separate job after the agent finishes.
#
# copilot-requests is the one exception, and it is not a repository
# permission: it authorizes Copilot inference through the Actions token,
# which is what pays for the model call.
permissions:
  contents: read
  issues: read
  pull-requests: read
  actions: read
  copilot-requests: write

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
