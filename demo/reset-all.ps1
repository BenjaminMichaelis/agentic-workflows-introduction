# Puts the demo repository into its on-stage starting state with one command.
# Runs the three per-demo resets, closes leftover generated issues, moves
# live-authoring leftovers aside, then verifies everything the talk depends on.
#
# Preview (read-only):  pwsh demo/reset-all.ps1 -Preview
# Reset:                pwsh demo/reset-all.ps1

param(
    [string]$Repo = 'BenjaminMichaelis/agentic-workflows-introduction',
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$protectedIssues = @(3, 8)
$generatedTitlePrefixes = @('Repo status report', '[aw] ', '[network-firewall-demo]', '[weekly digest]')
$authoringLeftovers = @('.github/workflows/weekly-digest.md', '.github/workflows/weekly-digest.lock.yml')
$botLogin = 'app/github-actions'

function Get-OpenIssues {
    gh issue list -R $Repo --state open --limit 200 --json number,title,labels,author | ConvertFrom-Json
}

function Get-OpenPullRequests {
    gh pr list -R $Repo --state open --limit 200 --json number,title,labels,headRefName | ConvertFrom-Json
}

function Test-GeneratedIssue($issue) {
    if ($protectedIssues -contains $issue.number) { return $false }
    if ($issue.author.login -ne $botLogin) { return $false }
    foreach ($prefix in $generatedTitlePrefixes) {
        if ($issue.title.StartsWith($prefix)) { return $true }
    }
    return $false
}

# --- 1. Local working tree -------------------------------------------------

$branch = git -C $repoRoot branch --show-current
if ($branch -ne 'main') {
    throw "Refusing to run on '$branch'; check out main first."
}

git -C $repoRoot fetch -q origin
if ($LASTEXITCODE -ne 0) { throw 'Could not fetch origin.' }

$leftovers = @($authoringLeftovers | Where-Object {
    (Test-Path (Join-Path $repoRoot $_)) -and -not (git -C $repoRoot ls-files -- $_)
})
if ($leftovers.Count -gt 0) {
    if ($Preview) {
        Write-Host "Would move aside live-authoring leftovers: $($leftovers -join ', ')"
    } else {
        $stash = Join-Path ([IO.Path]::GetTempPath()) ('weekly-digest-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        New-Item -ItemType Directory -Path $stash | Out-Null
        foreach ($path in $leftovers) { Move-Item (Join-Path $repoRoot $path) $stash }
        Write-Host "Moved live-authoring leftovers to $stash"
    }
}

# Line-ending-only differences (CRLF vs LF) show as modified but have no content
# change; refreshing the index clears them. Anything else is real work.
if (-not $Preview) { git -C $repoRoot update-index -q --refresh | Out-Null }
$realChanges = foreach ($line in @(git -C $repoRoot status --porcelain --untracked-files=all)) {
    $path = $line.Substring(3).Trim('"')
    if ($leftovers -contains $path) { continue }
    if ($line.StartsWith(' M')) {
        git -C $repoRoot diff --quiet -- $path 2>$null
        if ($LASTEXITCODE -eq 0) { continue }
    }
    $line
}
if ($realChanges) {
    $message = "Local changes that are not line-ending noise:`n  $($realChanges -join "`n  ")`nCommit, stash, or discard them yourself first."
    if ($Preview) { Write-Warning $message } else { throw $message }
}

# --- 2. What the reset will touch -------------------------------------------

$openIssues = @(Get-OpenIssues)
$openPrs = @(Get-OpenPullRequests)
$chainIssues = @($openIssues | Where-Object { $_.labels.name -contains 'ci-failure' -and $protectedIssues -notcontains $_.number })
$generatedIssues = @($openIssues | Where-Object { (Test-GeneratedIssue $_) -and $_.labels.name -notcontains 'ci-failure' })
$demoPrs = @($openPrs | Where-Object { $_.labels.name -contains 'ci-fix' -or $_.labels.name -contains 'dependency-fix' })
$otherPrs = @($openPrs | Where-Object { $demoPrs.number -notcontains $_.number })
$otherIssues = @($openIssues | Where-Object {
    $chainIssues.number -notcontains $_.number -and $generatedIssues.number -notcontains $_.number
})

Write-Host ''
Write-Host 'Reset plan:'
Write-Host "  CI chain issues to close:   $(if ($chainIssues) { ($chainIssues | ForEach-Object { "#$($_.number)" }) -join ' ' } else { 'none' })"
Write-Host "  Demo PRs to close:          $(if ($demoPrs) { ($demoPrs | ForEach-Object { "#$($_.number)" }) -join ' ' } else { 'none' })"
Write-Host "  Generated issues to close:  $(if ($generatedIssues) { ($generatedIssues | ForEach-Object { "#$($_.number)" }) -join ' ' } else { 'none' })"
Write-Host '  Re-arm: issue #3 (injection), issue #8 + Newtonsoft.Json 12.0.1 (dependency-fix), CsvHelper 19.0.0 (chain)'
foreach ($pr in $otherPrs) { Write-Warning "Leaving open PR #$($pr.number) '$($pr.title)' - the live repo-status report will mention it." }
foreach ($issue in $otherIssues) { Write-Warning "Leaving open issue #$($issue.number) '$($issue.title)'." }

# --- 3. Reset ----------------------------------------------------------------

if (-not $Preview) {
    Write-Host ''
    & (Join-Path $PSScriptRoot 'reset-ci-chain.ps1') -Repo $Repo
    & (Join-Path $PSScriptRoot 'reset-dependency-fix.ps1') -Repo $Repo
    & (Join-Path $PSScriptRoot 'reset.ps1') -Repo $Repo

    foreach ($issue in $generatedIssues) {
        gh issue close $issue.number -R $Repo --reason 'not planned' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Could not close issue #$($issue.number)." }
        Write-Host "Closed generated issue #$($issue.number) '$($issue.title)'."
    }
    git -C $repoRoot fetch -q origin
}

# --- 4. Verify ---------------------------------------------------------------

$results = [ordered]@{}
$csproj = git -C $repoRoot show origin/main:demo/ci-chain/CiChain.csproj
$results['CsvHelper 19.0.0 on origin/main (chain armed)'] = [bool]($csproj -match 'CsvHelper" Version="19\.0\.0"')
$toil = git -C $repoRoot show origin/main:demo/toil-repro/ToilRepro.csproj
$results['Newtonsoft.Json 12.0.1 on origin/main (fallback armed)'] = [bool]($toil -match 'Newtonsoft\.Json" Version="12\.0\.1"')

$issue3 = gh api "repos/$Repo/issues/3" | ConvertFrom-Json
$results['Issue #3 closed with 0 comments (injection armed)'] = ($issue3.state -eq 'closed' -and $issue3.comments -eq 0)
$issue8 = gh api "repos/$Repo/issues/8" | ConvertFrom-Json
$results['Issue #8 closed (dependency-fix armed)'] = ($issue8.state -eq 'closed')

$openIssues = @(Get-OpenIssues)
$openPrs = @(Get-OpenPullRequests)
$results['No open ci-failure issues'] = -not ($openIssues | Where-Object { $_.labels.name -contains 'ci-failure' })
$results['No open ci-fix / dependency-fix PRs'] = -not ($openPrs | Where-Object { $_.labels.name -contains 'ci-fix' -or $_.labels.name -contains 'dependency-fix' })
$results['No open generated issues (status reports, [aw], firewall)'] = -not ($openIssues | Where-Object { Test-GeneratedIssue $_ })
$results['No weekly-digest files in .github/workflows'] = -not ($authoringLeftovers | Where-Object { Test-Path (Join-Path $repoRoot $_) })

git -C $repoRoot update-index -q --refresh 2>$null | Out-Null
$ahead = git -C $repoRoot rev-list --count origin/main..HEAD
$behind = git -C $repoRoot rev-list --count HEAD..origin/main
$results['Local main matches origin/main'] = ($ahead -eq '0' -and $behind -eq '0')

Write-Host ''
Write-Host $(if ($Preview) { 'Current state (preview - nothing changed):' } else { 'Demo readiness:' })
foreach ($entry in $results.GetEnumerator()) {
    Write-Host ("  [{0}] {1}" -f $(if ($entry.Value) { 'ok' } else { '!!' }), $entry.Key)
}

$ci = gh run list -R $Repo --workflow ci.yml --branch main --limit 1 --json status,conclusion,headSha,url | ConvertFrom-Json | Select-Object -First 1
if ($ci) {
    Write-Host "  [..] Latest CI on main: $($ci.status) $($ci.conclusion) ($($ci.url)) - should finish green before you walk on."
}

if ($results.Values -contains $false) {
    if ($Preview) { Write-Host "`nRun without -Preview to reset." } else { exit 1 }
} else {
    Write-Host "`nReady. Act 0 trigger:  pwsh demo/trigger-ci-chain.ps1"
}
