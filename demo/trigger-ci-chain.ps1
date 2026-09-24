# Re-arms the CI failure demo by committing the known CsvHelper breaking bump.
# Run only from a clean main branch; the failing CI run hands off to ci-doctor.

param(
    [string]$Repo = 'BenjaminMichaelis/agentic-workflows-introduction'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

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

$workingTree = git -C $repoRoot status --porcelain --untracked-files=all
if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect the Git working tree.'
}
if ($workingTree) {
    throw 'Refusing to run because the working tree has uncommitted changes.'
}

$relativePath = 'demo/ci-chain/CiChain.csproj'
$csprojPath = Join-Path $PSScriptRoot 'ci-chain\CiChain.csproj'
$csproj = [System.IO.File]::ReadAllText($csprojPath)
$expectedPin = '(?<=<PackageReference Include="CsvHelper" Version=")19\.0\.0(?=")'
if ($csproj -notmatch $expectedPin) {
    throw 'Expected CsvHelper 19.0.0 in demo/ci-chain/CiChain.csproj before triggering the demo.'
}

$updatedCsproj = [regex]::Replace($csproj, $expectedPin, '20.0.0')
[System.IO.File]::WriteAllText(
    $csprojPath,
    $updatedCsproj,
    [System.Text.UTF8Encoding]::new($false)
)

git -C $repoRoot add -- $relativePath
if ($LASTEXITCODE -ne 0) {
    throw 'Could not stage the CsvHelper version bump.'
}

git -C $repoRoot commit -m 'chore(deps): bump CsvHelper from 19.0.0 to 20.0.0 in demo/ci-chain'
if ($LASTEXITCODE -ne 0) {
    throw 'Could not commit the CsvHelper version bump.'
}

$commit = git -C $repoRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0) {
    throw 'Could not read the new commit SHA.'
}

git -C $repoRoot push origin main
if ($LASTEXITCODE -ne 0) {
    throw 'The commit was created locally, but pushing main failed.'
}

$runUrl = $null
for ($attempt = 0; $attempt -lt 12 -and -not $runUrl; $attempt++) {
    $runJson = gh run list `
        --repo $Repo `
        --workflow ci.yml `
        --branch main `
        --commit $commit `
        --limit 1 `
        --json url,headSha
    if ($LASTEXITCODE -eq 0 -and $runJson) {
        $runs = @($runJson | ConvertFrom-Json)
        $matchingRun = $runs | Where-Object { $_.headSha -eq $commit } | Select-Object -First 1
        if ($matchingRun) {
            $runUrl = $matchingRun.url
        }
    }
    if (-not $runUrl -and $attempt -lt 11) {
        Start-Sleep -Seconds 5
    }
}

if ($runUrl) {
    Write-Host "CI run: $runUrl"
} else {
    Write-Host "CI was pushed for commit $commit; open https://github.com/$Repo/actions/workflows/ci.yml"
}
