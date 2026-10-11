param(
    [ValidateSet('Windows','Android','Test')]
    [string]$Target = 'Windows',
    [string]$GodotPath = ''
)
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrEmpty($GodotPath)) {
    $GodotPath = Join-Path $PSScriptRoot 'godot\Godot_v4.6.3-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $GodotPath)) {
    throw 'Godot was not found. Install Godot 4.6.3 and pass its executable through -GodotPath.'
}
$gamePath = Join-Path $projectRoot 'game'
if ($Target -eq 'Test') {
    & $GodotPath --headless --path $gamePath --script res://tests.gd
} elseif ($Target -eq 'Windows') {
    $outputFolder = Join-Path $projectRoot 'builds\windows'
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    # Preserve the official editor executable's signature. It can run the
    # companion native game pack and avoids an unsigned local runtime binary.
    $runtimePath = $GodotPath -replace '_console.exe$', '.exe'
    $presetPath = Join-Path $gamePath 'export_presets.cfg'
    $originalPreset = Get-Content -LiteralPath $presetPath -Raw
    $nextPreset = $originalPreset.IndexOf('[preset.1]')
    $windowsPreset = $originalPreset.Substring(0,$nextPreset).Replace('custom_template/release=""',('custom_template/release="' + $runtimePath.Replace('\','/') + '"'))
    $buildPreset = $windowsPreset + $originalPreset.Substring($nextPreset)
    try {
        [System.IO.File]::WriteAllText($presetPath,$buildPreset)
        & $GodotPath --headless --path $gamePath --export-release 'Windows Desktop' (Join-Path $outputFolder 'RecallQuest.exe')
        $buildExitCode = $LASTEXITCODE
    } finally {
        [System.IO.File]::WriteAllText($presetPath,$originalPreset)
    }
    if ($buildExitCode -ne 0) { throw "Windows export failed with code $buildExitCode" }
} else {
    $outputFolder = Join-Path $projectRoot 'builds\android'
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    & $GodotPath --headless --path $gamePath --export-debug Android (Join-Path $outputFolder 'RecallQuest.apk')
}
if ($LASTEXITCODE -ne 0) { throw "Godot $Target operation failed with code $LASTEXITCODE" }
