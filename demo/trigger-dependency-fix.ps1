# Fires the dependency-fix demo.
# Reopens the dedicated vulnerability-signal issue, which is the configured
# trigger for .github/workflows/dependency-fix.md. Mirrors the
# `gh issue reopen 3` pattern used to arm the Act 5 prompt-injection demo.

param(
    [string]$Repo  = 'BenjaminMichaelis/agentic-workflows-introduction',
    [int]   $Issue = 8
)

$ErrorActionPreference = 'Stop'

gh issue reopen $Issue -R $Repo

Write-Host "Fired: issue #$Issue reopened in $Repo."
Write-Host "Watch it run:  gh run watch -R $Repo `$(gh run list -R $Repo --workflow=dependency-fix.lock.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
Write-Host "Re-arm with:   pwsh demo/reset-dependency-fix.ps1"
