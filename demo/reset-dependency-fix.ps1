# Re-arms the dependency-fix demo.
# Closes the vulnerability-signal issue, closes any pull requests the agent
# opened on a previous run (and deletes their branches), and restores
# demo/toil-repro/ToilRepro.csproj to the pinned vulnerable version so the
# next `dotnet list package --vulnerable` run - and the next agent run - both
# start from the same real finding.
#
# Does not touch demo/reset.ps1 or the Act 5 injection demo (issue #3).

param(
    [string]$Repo  = 'BenjaminMichaelis/agentic-workflows-introduction',
    [int]   $Issue = 8
)

$ErrorActionPreference = 'Stop'

# 1. Close the trigger issue so the next `gh issue reopen` fires cleanly.
gh issue close $Issue -R $Repo 2>&1 | Out-Null

# 2. Close any pull requests opened by previous runs of this demo and delete
#    their branches, so the PR list stays clean for the next run.
$prs = gh pr list -R $Repo --state open --label dependency-fix --json number,headRefName | ConvertFrom-Json
foreach ($pr in $prs) {
    gh pr close $pr.number -R $Repo --delete-branch 2>&1 | Out-Null
    Write-Host "Closed pull request #$($pr.number) ($($pr.headRefName)) and deleted its branch."
}

# 3. Restore the sample project's pinned vulnerable version, in case a
#    previous run's PR was merged into the default branch.
$csproj = Join-Path $PSScriptRoot 'toil-repro\ToilRepro.csproj'
$vulnerableXml = @'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="12.0.1" />
  </ItemGroup>

</Project>
'@
Set-Content -Path $csproj -Value $vulnerableXml -NoNewline
git -C $PSScriptRoot\.. add demo/toil-repro/ToilRepro.csproj
$staged = git -C $PSScriptRoot\.. diff --cached --name-only
if ($staged) {
    git -C $PSScriptRoot\.. commit -m "demo: re-arm dependency-fix (restore vulnerable Newtonsoft.Json 12.0.1)" | Out-Null
    git -C $PSScriptRoot\.. push | Out-Null
    Write-Host "Restored demo/toil-repro/ToilRepro.csproj to the vulnerable pin and pushed."
} else {
    git -C $PSScriptRoot\.. reset demo/toil-repro/ToilRepro.csproj | Out-Null
    Write-Host "demo/toil-repro/ToilRepro.csproj was already at the vulnerable pin."
}

Write-Host "Demo re-armed: issue #$Issue closed, $(@($prs).Count) PR(s) closed."
Write-Host "Fire with:  pwsh demo/trigger-dependency-fix.ps1"
