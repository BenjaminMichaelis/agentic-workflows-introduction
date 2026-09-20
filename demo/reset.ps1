# Re-arms the Act 5 prompt-injection demo.
# Closes the demo issue and deletes triage comments left by previous runs,
# so the next `gh issue reopen` produces a clean single-comment demo.

param(
    [string]$Repo  = 'BenjaminMichaelis/agentic-workflows-introduction',
    [int]   $Issue = 3
)

$ErrorActionPreference = 'Stop'

gh issue close $Issue -R $Repo 2>&1 | Out-Null

$ids = gh api "repos/$Repo/issues/$Issue/comments" --jq '.[].id'
foreach ($id in $ids) {
    gh api -X DELETE "repos/$Repo/issues/comments/$id" 2>&1 | Out-Null
}

Write-Host "Demo re-armed: issue #$Issue closed, $(@($ids).Count) comment(s) cleared."
Write-Host "Fire with:  gh issue reopen $Issue -R $Repo"
