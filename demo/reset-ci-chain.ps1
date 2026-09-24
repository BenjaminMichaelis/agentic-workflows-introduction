# Re-arms the CI chain: close its prior outputs and restore the green fixture.
# Issue #3 (the injection demo) and issue #8 (dependency-fix) are never touched.

param(
    [string]$Repo = 'BenjaminMichaelis/agentic-workflows-introduction'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$protectedNumbers = @(3, 8)
$relativePaths = @(
    'demo/ci-chain/CiChain.csproj',
    'demo/ci-chain/Program.cs'
)

$branch = git -C $repoRoot branch --show-current
if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine the current Git branch.'
}
if ($branch -ne 'main') {
    throw "Refusing to run on '$branch'; check out main first."
}

git -C $repoRoot pull --ff-only origin main
if ($LASTEXITCODE -ne 0) {
    throw 'Could not fast-forward main from origin; resolve that first.'
}

$stagedPaths = @(git -C $repoRoot diff --cached --name-only)
if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect the Git index.'
}
if ($stagedPaths.Count -gt 0) {
    throw 'Refusing to run while staged changes exist; commit or unstage them first.'
}

$issueJson = gh issue list `
    --repo $Repo `
    --state open `
    --label ci-failure `
    --limit 1000 `
    --json number,title
if ($LASTEXITCODE -ne 0) {
    throw 'Could not list open ci-failure issues.'
}
$issues = @($issueJson | ConvertFrom-Json)
$closedIssues = 0
foreach ($issue in $issues) {
    $number = [int]$issue.number
    if ($protectedNumbers -contains $number) {
        Write-Host "Preserving protected issue #$number."
        continue
    }
    gh issue close $number --repo $Repo
    if ($LASTEXITCODE -ne 0) {
        throw "Could not close issue #$number."
    }
    $closedIssues++
    Write-Host "Closed ci-failure issue #$number."
}

$prJson = gh pr list `
    --repo $Repo `
    --state open `
    --label ci-fix `
    --limit 1000 `
    --json number,headRefName
if ($LASTEXITCODE -ne 0) {
    throw 'Could not list open ci-fix pull requests.'
}
$pullRequests = @($prJson | ConvertFrom-Json)
$closedPullRequests = 0
foreach ($pr in $pullRequests) {
    $number = [int]$pr.number
    if ($protectedNumbers -contains $number) {
        Write-Host "Preserving protected pull request #$number."
        continue
    }
    gh pr close $number --repo $Repo --delete-branch
    if ($LASTEXITCODE -ne 0) {
        throw "Could not close pull request #$number."
    }
    $closedPullRequests++
    Write-Host "Closed ci-fix pull request #$number and deleted branch '$($pr.headRefName)'."
}

$csprojPath = Join-Path $PSScriptRoot 'ci-chain\CiChain.csproj'
$csproj = [System.IO.File]::ReadAllText($csprojPath)
if ($csproj -notmatch '<PackageReference Include="CsvHelper" Version="[^"]+"') {
    throw 'Could not find the CsvHelper PackageReference in CiChain.csproj.'
}
$restoredCsproj = [regex]::Replace(
    $csproj,
    '(?<=<PackageReference Include="CsvHelper" Version=")[^"]+(?=")',
    '19.0.0'
)
[System.IO.File]::WriteAllText(
    $csprojPath,
    $restoredCsproj,
    [System.Text.UTF8Encoding]::new($false)
)

$restoredProgram = @'
using CsvHelper;
using CsvHelper.Configuration;
using System.Globalization;

var configuration = new CsvConfiguration(CultureInfo.InvariantCulture);
configuration.HasHeaderRecord = false;

using var writer = new StringWriter();
using var csv = new CsvWriter(writer, configuration);
csv.WriteField("demo");
csv.NextRecord();
Console.Write(writer.ToString());
'@
$restoredProgram = $restoredProgram.TrimEnd("`r", "`n") + [Environment]::NewLine
$programPath = Join-Path $PSScriptRoot 'ci-chain\Program.cs'
[System.IO.File]::WriteAllText(
    $programPath,
    $restoredProgram,
    [System.Text.UTF8Encoding]::new($false)
)

git -C $repoRoot diff --quiet -- $relativePaths
$diffExitCode = $LASTEXITCODE
if ($diffExitCode -eq 0) {
    Write-Host 'The CI-chain files are already at the green baseline; no commit or push needed.'
} elseif ($diffExitCode -eq 1) {
    git -C $repoRoot add -- $relativePaths
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not stage the restored CI-chain files.'
    }

    $stagedPaths = @(git -C $repoRoot diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not inspect the staged CI-chain files.'
    }
    $unexpectedPaths = @($stagedPaths | Where-Object { $relativePaths -notcontains $_ })
    if ($unexpectedPaths.Count -gt 0) {
        throw "Refusing to commit unexpected staged paths: $($unexpectedPaths -join ', ')"
    }

    git -C $repoRoot commit -m 'demo: re-arm ci-chain (restore CsvHelper 19.0.0)'
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not commit the restored CI-chain files.'
    }
    git -C $repoRoot push origin main
    if ($LASTEXITCODE -ne 0) {
        throw 'The re-arm commit was created locally, but pushing main failed.'
    }
    Write-Host 'Restored and pushed the green CI-chain baseline.'
} else {
    throw 'Could not compare the CI-chain files with the current commit.'
}

Write-Host "Demo re-armed: closed $closedIssues issue(s) and $closedPullRequests pull request(s)."
