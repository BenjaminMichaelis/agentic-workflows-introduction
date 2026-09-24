---
on:
  schedule: weekly
permissions:
  contents: read
  issues: read
  pull-requests: read
  copilot-requests: write
safe-outputs:
  create-issue:
    title-prefix: "[weekly digest] "
    max: 1
---

# Weekly digest

Look at everything merged into the default branch in the last seven days,
plus any issues opened or closed in that window.

Write one short issue a new teammate could read in two minutes:
what changed, what broke, and what is still open. Link every PR and issue
you mention. If nothing happened this week, say so in one sentence.
