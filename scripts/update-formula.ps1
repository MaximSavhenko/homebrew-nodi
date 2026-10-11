param([string]$Owner='MaximSavhenko')
$ErrorActionPreference='Stop'
$headers=@{Accept='application/vnd.github+json';'User-Agent'='nodi-homebrew-updater';'X-GitHub-Api-Version'='2022-11-28'}
if ($env:GH_TOKEN) { $headers.Authorization='Bearer '+$env:GH_TOKEN }
try { $release=Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/nodi/releases/latest" -Headers $headers } catch {
    if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 404) { Write-Output 'No stable release yet; formula unchanged.'; return }
    throw 'Cannot read Nodi release metadata.'
}
if ($release.draft -or $release.prerelease -or $release.tag_name -notmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw 'Stable versioned release required.' }
$version=$release.tag_name.Substring(1)
$base="https://github.com/$Owner/nodi/releases/download/$($release.tag_name)"
function Read-NodiReleaseAsset([string]$Name) {
    $assets=@($release.assets | Where-Object { $_.name -ceq $Name -and $_.state -ceq 'uploaded' })
    if ($assets.Count -ne 1 -or $assets[0].browser_download_url -cne "$base/$Name" -or $assets[0].size -gt 4194304) { throw "Invalid release metadata asset: $Name" }
    # Public downloads carry no Authorization header, including on CDN redirects.
    try { $content=(Invoke-WebRequest -Uri "$base/$Name" -MaximumRedirection 5).Content; if ($content -is [byte[]]) { return [Text.Encoding]::UTF8.GetString($content) }; return [string]$content } catch { throw "Cannot download public release asset: $Name" }
}
$receipt=Read-NodiReleaseAsset 'validation.json' | ConvertFrom-Json
if ($receipt.schema -ne 1 -or $receipt.confirmed -ne $true -or $receipt.version -cne $version -or $receipt.repository -cne "$Owner/nodi" -or $receipt.source_commit -notmatch '^[0-9a-f]{40}$') { throw 'Missing confirmed release receipt.' }
foreach ($check in @('windows-amd64','darwin-arm64','darwin-amd64','winget-validate')) { if ($check -notin $receipt.checks) { throw "Release check missing: $check" } }
$rows=(Read-NodiReleaseAsset 'SHA256SUMS') -split "`n"
$formula=Read-NodiReleaseAsset 'nodi.rb'
if ($formula -notmatch ([regex]::Escape("version `"$version`""))) { throw 'Formula version mismatch.' }
foreach ($asset in @('nodi-darwin-arm64.zip','nodi-darwin-amd64.zip')) {
    $checksumRows=@($rows | Where-Object { $_.TrimEnd() -cmatch "^[0-9a-f]{64}  $([regex]::Escape($asset))$" })
    $records=@($receipt.assets | Where-Object { $_.name -ceq $asset })
    if ($checksumRows.Count -ne 1 -or $records.Count -ne 1 -or $records[0].sha256 -cne $checksumRows[0].Substring(0,64)) { throw 'Release receipt and checksums differ.' }
    if ($formula -notmatch ([regex]::Escape("$base/$asset")) -or $formula -notmatch ([regex]::Escape($records[0].sha256))) { throw 'Formula URLs/checksums differ from release.' }
}
$formulaPath=Join-Path (Split-Path $PSScriptRoot -Parent) 'Formula/nodi.rb'
if (Test-Path -LiteralPath $formulaPath) {
    $current=Get-Content -LiteralPath $formulaPath -Raw
    $versionMatch=[regex]::Match($current,'version "([0-9]+\.[0-9]+\.[0-9]+)"')
    if ($versionMatch.Success -and [version]$versionMatch.Groups[1].Value -gt [version]$version) { throw 'Formula downgrade refused.' }
}
New-Item -ItemType Directory -Path (Split-Path $formulaPath -Parent) -Force | Out-Null
[IO.File]::WriteAllText($formulaPath,$formula.Replace("`r`n","`n").TrimEnd()+"`n",[Text.UTF8Encoding]::new($false))
Write-Output "Formula synchronized to confirmed Nodi $version."
