param(
    [string]$Godot = $env:GODOT_BIN,
    [ValidateSet("Web", "Android")][string]$Target = "Web"
)
$ErrorActionPreference = "Stop"
if (-not $Godot) { $Godot = "godot" }
$projectRoot = Split-Path -Parent $PSScriptRoot
& $Godot --headless --editor --path $projectRoot --import --quit
if ($LASTEXITCODE -ne 0) { throw "Godot import failed" }
& $Godot --headless --path $projectRoot --script self_test.gd
if ($LASTEXITCODE -ne 0) { throw "Puzzle verification failed" }
if ($Target -eq "Web") {
    $output = Join-Path $projectRoot "build/web/index.html"
    New-Item -ItemType Directory -Path (Split-Path $output) -Force | Out-Null
    & $Godot --headless --path $projectRoot --export-release Web $output
} else {
    $output = Join-Path $projectRoot "build/android/reverse-debug.apk"
    New-Item -ItemType Directory -Path (Split-Path $output) -Force | Out-Null
    & $Godot --headless --path $projectRoot --export-debug Android $output
}
if ($LASTEXITCODE -ne 0) { throw "Godot export failed" }
Write-Output $output
