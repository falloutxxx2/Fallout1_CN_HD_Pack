# Fallout 1 (Steam) - undo the Chinese + hi-res patch install.
#
# Restores every file that install.ps1 overwrote (from backup\<timestamp>\) and
# deletes the files it added.  The newest backup is used unless -Backup is given.
#
# Usage:  uninstall.cmd
#         uninstall.cmd -Backup 20261124_015500
#         uninstall.cmd -KeepShortcuts

param(
    [string]$GameDir = '',
    [string]$Backup  = '',
    [switch]$KeepShortcuts
)

$ErrorActionPreference = 'Stop'
$packDir = Split-Path -Parent $PSScriptRoot

function Say([string]$text) { Write-Host ('  ' + $text) }
function Die([string]$text) { Write-Host ''; Write-Host ('  !! ' + $text) -ForegroundColor Red; Write-Host ''; exit 1 }

Write-Host ''
Write-Host '  Fallout 1 (Steam) - uninstall Chinese + hi-res patch'
Write-Host '  =================================================='
Write-Host ''

$backupRoot = Join-Path $packDir 'backup'
if (-not (Test-Path -LiteralPath $backupRoot)) { Die 'no backup folder found - nothing to undo.' }

if ($Backup) {
    $dir = Join-Path $backupRoot $Backup
    if (-not (Test-Path -LiteralPath $dir)) { $dir = $Backup }
} else {
    $dir = (Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name | Select-Object -Last 1).FullName
}
if (-not (Test-Path -LiteralPath $dir)) { Die ("backup not found: " + $dir) }
$manifestPath = Join-Path $dir 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { Die ("not a patch-pack backup (manifest.json missing): " + $dir) }

$doc = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$gameDir = if ($GameDir) { $GameDir } else { $doc.gameDir }
if (-not (Test-Path -LiteralPath $gameDir)) { Die ("game folder not found: " + $gameDir) }

$running = Get-Process -Name FALLOUTW, fallout -ErrorAction SilentlyContinue
if ($running) { Die 'Fallout is running - close it and start uninstall again.' }

$entries = @($doc.files)
Say ("game folder : " + $gameDir)
Say ("backup      : " + $dir)
Say ("files       : " + $entries.Count)
Write-Host ''

$restored = 0
$removed  = 0
$missing  = 0
foreach ($e in $entries) {
    $target = Join-Path $gameDir $e.path
    if ($e.existed) {
        $src = Join-Path $dir $e.path
        if (Test-Path -LiteralPath $src) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
            Copy-Item -LiteralPath $src -Destination $target -Force
            $restored++
        } else {
            $missing++
            Say ('WARN: missing in backup: ' + $e.path)
        }
    } elseif (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Force
        $removed++
    }
}
Say ("restored {0} original files, removed {1} added files" -f $restored, $removed)
if ($missing -gt 0) { Say ("WARN: {0} files could not be restored" -f $missing) }

# drop directories that the install created and that are empty again
$dirs = @($entries | ForEach-Object { Split-Path -Parent (Join-Path $gameDir $_.path) } |
          Sort-Object -Unique | Sort-Object -Property Length -Descending)
foreach ($d in $dirs) {
    if ((Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue)) {
        Remove-Item -LiteralPath $d -Force -ErrorAction SilentlyContinue
    }
}

if (-not $KeepShortcuts) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    foreach ($n in @('Fallout 中文窗口', 'Fallout 中文全屏')) {
        $p = Join-Path $desktop ($n + '.lnk')
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; Say ('removed shortcut: ' + $p) }
    }
}

Write-Host ''
Write-Host '  done - the game folder is back to how it was before install.' -ForegroundColor Green
Write-Host '  The backup folder is kept, delete it yourself once you are sure.' -ForegroundColor Green
Write-Host ''
