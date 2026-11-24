# 把 payload\ + tools\ + 两个 .cmd + README.txt 打成一个可直接分发的补丁包。
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File .\build-release.ps1
#         powershell ... -File .\build-release.ps1 -Payload "D:\other\files" -Out "D:\tmp\pack.zip"
#
# 产物结构和 install.cmd 期望的完全一致：files\  tools\  install.cmd  uninstall.cmd  README.txt

param(
    [string]$Payload = '',
    [string]$Out     = ''
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
if (-not $Payload) { $Payload = Join-Path $repo 'payload' }
if (-not $Out)     { $Out     = Join-Path $repo 'Fallout1_CN_HD_Pack.zip' }

function Die([string]$msg) { Write-Host ''; Write-Host ('  !! ' + $msg) -ForegroundColor Red; Write-Host ''; exit 1 }
function Say([string]$msg) { Write-Host ('  ' + $msg) }

Write-Host ''
Write-Host '  build-release - Fallout 1 CN + hi-res patch pack'
Write-Host '  ==============================================='
Write-Host ''

# ---------------------------------------------------------------- checks
if (-not (Test-Path -LiteralPath $Payload -PathType Container)) { Die ("payload folder not found: " + $Payload) }

$required = @(
    'FALLOUTW.EXE',
    'fallout_font.dll',
    'f1_res.dll',
    'f1_res.ini',
    'fallout_chinese_windowed.ps1',
    'Fallout_chinese_windowed.cmd',
    'DATA\TEXT\ENGLISH',
    'DATA\art\intrface'
)
$missing = @()
foreach ($rel in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $Payload $rel))) { $missing += $rel }
}
if ($missing.Count) {
    Die ("payload is incomplete, missing: " + ($missing -join ', ') + "`r`n     see payload/README.md")
}
if (Test-Path -LiteralPath (Join-Path $Payload 'backup')) {
    Say 'note: payload contains a backup\ folder - it will be left out of the zip.'
}

$stage = Join-Path ([IO.Path]::GetTempPath()) ('fopack_' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $stage | Out-Null

try {
    # ------------------------------------------------------------ assemble
    # payload\README.md 是说明文件，backup\ 是安装脚本的产物，都不属于补丁内容
    $stageFiles = Join-Path $stage 'files'
    New-Item -ItemType Directory -Path $stageFiles -Force | Out-Null
    Get-ChildItem -LiteralPath $Payload -Force |
        Where-Object { $_.Name -notin @('README.md', 'backup') } |
        ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $stageFiles -Recurse -Force }
    Remove-Item -LiteralPath (Join-Path $stageFiles 'backup') -Recurse -Force -ErrorAction SilentlyContinue

    Copy-Item -LiteralPath (Join-Path $repo 'tools') -Destination (Join-Path $stage 'tools') -Recurse
    foreach ($f in @('install.cmd', 'uninstall.cmd', 'README.txt')) {
        $src = Join-Path $repo $f
        if (-not (Test-Path -LiteralPath $src)) { Die ("missing file in repo: " + $f) }
        Copy-Item -LiteralPath $src -Destination $stage
    }

    $payloadCount = (Get-ChildItem -LiteralPath (Join-Path $stage 'files') -Recurse -File).Count
    $payloadBytes = (Get-ChildItem -LiteralPath (Join-Path $stage 'files') -Recurse -File | Measure-Object Length -Sum).Sum
    Say ("payload: {0} files, {1:N2} MB" -f $payloadCount, ($payloadBytes / 1MB))

    # ------------------------------------------------------------- compress
    $outDir = Split-Path -Parent $Out
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out -Force }

    # Compress-Archive on Windows PowerShell 5.1 writes backslash separators into
    # the zip, which non-Windows extractors turn into flat file names. Entries are
    # created by hand so every path is guaranteed to use '/'.
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::Open($Out, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($f in (Get-ChildItem -LiteralPath $stage -Recurse -File | Sort-Object FullName)) {
            $entryName = $f.FullName.Substring($stage.Length + 1).Replace('\', '/')
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $f.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        }
    } finally {
        $zip.Dispose()
    }

    # --------------------------------------------------------------- report
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($Out)
    $entries = $zip.Entries.Count
    $zip.Dispose()

    $item = Get-Item -LiteralPath $Out
    $hash = (Get-FileHash -LiteralPath $Out -Algorithm SHA256).Hash
    Write-Host ''
    Say ("built: {0}" -f $item.FullName)
    Say ("size : {0:N2} MB ({1} bytes), {2} entries" -f ($item.Length / 1MB), $item.Length, $entries)
    Say ("sha256: {0}" -f $hash)
    Write-Host ''
} finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
