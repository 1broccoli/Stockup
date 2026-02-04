# Manual CurseForge Upload Script
param(
    [string]$Version = "1.0.3",
    [string]$Token = $env:CURSEFORGE_API_TOKEN
)

if (-not $Token) {
    Write-Host "Error: CURSEFORGE_API_TOKEN not set" -ForegroundColor Red
    Write-Host "Usage: .\upload-curseforge.ps1 -Version 1.0.3 -Token YOUR_TOKEN"
    exit 1
}

# Create package
Write-Host "Creating package..." -ForegroundColor Green
$packagePath = "StockUp"
if (Test-Path $packagePath) {
    Remove-Item $packagePath -Recurse -Force
}
New-Item -ItemType Directory -Path $packagePath | Out-Null

# Copy files
Copy-Item *.lua, *.toc, LICENSE, README.md, CHANGES.md, CURSEFORGE_DESCRIPTION.md -Destination $packagePath
Copy-Item Db, Libs, Media -Destination $packagePath -Recurse

# Create zip
$zipPath = "StockUp.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Compress-Archive -Path $packagePath -DestinationPath $zipPath

Write-Host "Package created: $zipPath" -ForegroundColor Green

# Upload to CurseForge using curl
Write-Host "Uploading to CurseForge..." -ForegroundColor Green

$metadata = "{`"changelog`":`"Version $Version`",`"changelogType`":`"text`",`"displayName`":`"$Version`",`"releaseType`":`"release`"}"

$curlCommand = "curl -X POST -H `"X-API-Token: $Token`" -F `"metadata=$metadata`" -F `"file=@StockUp.zip`" https://www.curseforge.com/api/projects/1447101/upload-file"

Write-Host "Executing: $curlCommand" -ForegroundColor Yellow
$result = Invoke-Expression $curlCommand

Write-Host $result

# Cleanup
Remove-Item $packagePath -Recurse -Force
Remove-Item $zipPath -Force

Write-Host "Done!" -ForegroundColor Green
