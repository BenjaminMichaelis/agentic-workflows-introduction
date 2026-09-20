This is a hands-on demo repository for Benjamin Michaelis's conference talk "AI Agents in GitHub Actions: Automate Beyond YAML."

## Fork this now

1. Open <https://github.com/BenjaminMichaelis/agentic-workflows-introduction>.
2. Click **Fork** and create your own copy.
3. Open your fork's **Actions** tab. If GitHub asks you to enable workflows on the fork, enable them.
4. Open `.github/workflows/repo-status.md` in your fork and read the frontmatter plus the short prompt body.
5. If your setup is ready, clone your fork, sign in with the GitHub CLI, and run the workflow with `gh aw run repo-status` from the clone.
6. If anything in setup fails, do not fight conference Wi-Fi; keep following from the files in this repo.

## Prerequisites to actually run a workflow

Running the workflow, not just reading it, requires all of the following:

- GitHub Actions enabled on your fork.
- The GitHub CLI (`gh`) installed and authenticated for your fork.
- The GitHub Agentic Workflows extension installed with `gh extension install github/gh-aw`.
- Model access and billing for the selected engine. This demo uses the `copilot` engine, so availability depends on your account or organization setup.

Not everyone will be able to run this live in a conference room. That is expected. You can still follow the talk by reading the Markdown workflow and the generated lock file.

## What to look at even if you can't run it

- `.github/workflows/repo-status.md` is the human-authored workflow: YAML frontmatter for configuration, then a plain Markdown prompt.
- `.github/workflows/repo-status.lock.yml` is the compiled GitHub Actions workflow that GitHub actually runs.
- In `repo-status.md`, compare the read-only `permissions:` block with the `safe-outputs:` block. That contrast is the safety-model teaching moment.
- The prompt is intentionally short enough to read on a phone. The point is not prompt cleverness; it is controlled, reviewable automation.

## What the `repo-status` workflow does

`repo-status` is a manual, read-only first demo. When a maintainer runs it, the agent looks at basic repository context and writes a short newcomer-friendly status report. The agent does not get direct GitHub write permissions. Instead, it requests a `create-issue` safe output, and a separate validated safe-output step creates the issue after the agent finishes.
