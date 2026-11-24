# Fallout 1 (Steam, appid 38400) - Simplified Chinese + hi-res patch installer.
#
# Copies the Chinese patch files (FALLOUTW.EXE with the 2007 font-DLL loader,
# fallout_font.dll, the Chinese *.MSG text and the Chinese interface art), the
# f1_res hi-res patch and the launcher scripts into the game folder.
# Every file that gets overwritten is backed up first, and uninstall.ps1 puts
# them all back.
#
# Usage:  install.cmd                       (auto-detects the Steam library)
#         install.cmd -GameDir "D:\Games\Fallout"
#         install.cmd -NoShortcuts

param(
    [string]$GameDir = '',
    [switch]$NoShortcuts
)

$ErrorActionPreference = 'Stop'
$packDir  = Split-Path -Parent $PSScriptRoot
$filesDir = Join-Path $packDir 'files'

function Say([string]$text) { Write-Host ('  ' + $text) }
function Die([string]$text) { Write-Host ''; Write-Host ('  !! ' + $text) -ForegroundColor Red; Write-Host ''; exit 1 }

function Test-GameDir([string]$dir) {
    if (-not $dir -or -not (Test-Path -LiteralPath $dir -PathType Container)) { return $false }
    $dat = (Test-Path -LiteralPath (Join-Path $dir 'master.dat')) -or (Test-Path -LiteralPath (Join-Path $dir 'MASTER.DAT'))
    $exe = (Test-Path -LiteralPath (Join-Path $dir 'falloutw.exe')) -or (Test-Path -LiteralPath (Join-Path $dir 'FALLOUTW.EXE'))
    return ($dat -and $exe)
}

function Get-SteamRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    try {
        $p = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction Stop).SteamPath
        if ($p) { $roots.Add($p.Replace('/', '\')) }
    } catch {}
    foreach ($k in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam')) {
        try {
            $v = (Get-ItemProperty -Path $k -Name InstallPath -ErrorAction Stop).InstallPath
            if ($v) { $roots.Add($v.Replace('/', '\')) }
        } catch {}
    }
    return $roots
}

function Get-LibraryFolders([string]$steamRoot) {
    $out = New-Object System.Collections.Generic.List[string]
    $vdf = Join-Path $steamRoot 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($line in (Get-Content -LiteralPath $vdf)) {
            if ($line -match '"path"\s+"([^"]+)"') { $out.Add($matches[1].Replace('\\', '\')) }
        }
    }
    if (Test-Path -LiteralPath (Join-Path $steamRoot 'steamapps')) { $out.Add($steamRoot) }
    return $out
}

function Find-GameDir {
    if ($GameDir) { return $GameDir }
    # the pack is normally unpacked inside the game folder
    $inside = Split-Path -Parent $packDir
    if (Test-GameDir $inside) { return $inside }
    $seen = @{}
    foreach ($root in (Get-SteamRoots)) {
        foreach ($lib in (Get-LibraryFolders $root)) {
            if ($seen.ContainsKey($lib)) { continue }
            $seen[$lib] = $true
            $cand = Join-Path $lib 'steamapps\common\Fallout'
            if (Test-GameDir $cand) { return $cand }
        }
    }
    foreach ($drive in @('C', 'D', 'E', 'F', 'G')) {
        foreach ($sub in @('SteamLibrary', 'Steam', 'Games\Steam', 'Program Files (x86)\Steam')) {
            $cand = Join-Path ($drive + ':\') ($sub + '\steamapps\common\Fallout')
            if (Test-GameDir $cand) { return $cand }
        }
    }
    return $null
}

function Set-IniValue([string]$file, [string]$key, [string]$value) {
    if (-not (Test-Path -LiteralPath $file)) { return }
    $t = [IO.File]::ReadAllText($file, [Text.Encoding]::Default)
    $pattern = "(?m)^([ \t]*" + [regex]::Escape($key) + "[ \t]*=).*$"
    if ($t -match $pattern) {
        $t = [regex]::Replace($t, $pattern, ('${1}' + $value))
    } else {
        $t = $t.TrimEnd() + "`r`n" + $key + '=' + $value + "`r`n"
    }
    [IO.File]::WriteAllText($file, $t, [Text.Encoding]::Default)
}

# ------------------------------------------------------------------ main
Write-Host ''
Write-Host '  Fallout 1 (Steam) - Simplified Chinese + hi-res patch installer'
Write-Host '  ============================================================='
Write-Host ''

if (-not (Test-Path -LiteralPath $filesDir)) { Die ("pack is incomplete, missing: " + $filesDir) }

$gameDir = Find-GameDir
if (-not $gameDir) {
    Die 'Fallout was not found. Run install.cmd -GameDir "<your Fallout folder>".'
}
$gameDir = (Resolve-Path -LiteralPath $gameDir).Path.TrimEnd('\')
if (-not (Test-GameDir $gameDir)) {
    Die ("this does not look like a Fallout 1 install: " + $gameDir)
}
Say ("game folder : " + $gameDir)

$running = Get-Process -Name FALLOUTW, fallout -ErrorAction SilentlyContinue
if ($running) { Die 'Fallout is running - close it and start install again.' }

$already = Test-Path -LiteralPath (Join-Path $packDir 'backup')
if ($already) { Say 'note: an earlier backup exists in backup\, it is kept as it is.' }

# ------------------------------------------------------------------ back up + copy
$stamp     = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupDir = Join-Path $packDir ('backup\' + $stamp)
$manifest  = New-Object System.Collections.Generic.List[object]
$srcFiles  = @(Get-ChildItem -LiteralPath $filesDir -Recurse -File)
$copied = 0
$kept   = 0
$saved  = 0
foreach ($f in $srcFiles) {
    $rel     = $f.FullName.Substring($filesDir.Length + 1)
    $target  = Join-Path $gameDir $rel
    $existed = Test-Path -LiteralPath $target
    if ($existed) {
        # identical content: nothing to do, no backup needed
        $same = ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)
        if ($same) { $kept++; continue }
        $b = Join-Path $backupDir $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $b) | Out-Null
        Copy-Item -LiteralPath $target -Destination $b -Force
        $saved++
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $f.FullName -Destination $target -Force
    $manifest.Add([pscustomobject]@{ path = $rel; existed = $existed })
    $copied++
}
Say ("files   : copied {0}, already up to date {1}, replaced+backed up {2}" -f $copied, $kept, $saved)

if ($saved -gt 0) {
    $doc = [pscustomobject]@{ timestamp = $stamp; gameDir = $gameDir; files = $manifest }
    [IO.File]::WriteAllText((Join-Path $backupDir 'manifest.json'), ($doc | ConvertTo-Json -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
    Say ("backup  : " + $backupDir)
} else {
    Say 'backup  : not needed, nothing was overwritten'
}

# ------------------------------------------------------------------ f1_res.ini
# A plain Steam start has to stay playable, so the ini is left in the safe
# state: basic mode (GRAPHICS_MODE=0) at 1920x1440 fullscreen. The launcher
# switches to DirectX 9 (2) itself and restores this state when the game closes.
$gameIni    = Join-Path $gameDir 'f1_res.ini'
$iniTargets = @($gameIni)
$appRoot    = Join-Path $env:APPDATA 'Fallout'
if (Test-Path -LiteralPath $appRoot) {
    # only the copy whose "path=" points at this game folder belongs to us
    foreach ($d in (Get-ChildItem -LiteralPath $appRoot -Directory -ErrorAction SilentlyContinue)) {
        $c = Join-Path $d.FullName 'f1_res.ini'
        if (-not (Test-Path -LiteralPath $c)) { continue }
        $t = [IO.File]::ReadAllText($c, [Text.Encoding]::Default)
        if ($t -match '(?im)^[ \t]*path[ \t]*=[ \t]*([^\r\n]+)') {
            if ($matches[1].Trim().TrimEnd('\') -ieq $gameDir) { $iniTargets += $c }
        }
    }
}
$iniTargets = @($iniTargets | Select-Object -Unique)
$uac = if ($iniTargets.Count -gt 1) { '1' } else { '0' }
foreach ($ini in $iniTargets) {
    Set-IniValue $ini 'path'                $gameDir   # f1_res data path = this install
    Set-IniValue $ini 'UAC_AWARE'           $uac
    Set-IniValue $ini 'GRAPHICS_MODE'       '0'
    Set-IniValue $ini 'SCALE_2X'            '0'
    Set-IniValue $ini 'SCR_WIDTH'           '1920'
    Set-IniValue $ini 'SCR_HEIGHT'          '1440'
    Set-IniValue $ini 'COLOUR_BITS'         '32'
    Set-IniValue $ini 'REFRESH_RATE'        '0'
    Set-IniValue $ini 'WINDOWED'            '0'
    Set-IniValue $ini 'WINDOWED_FULLSCREEN' '0'
    Set-IniValue $ini 'WIN_DATA'            '0'
    Say ("ini     : " + $ini + "  (GRAPHICS_MODE=0, 1920x1440 fullscreen)")
}

# ------------------------------------------------------------------ shortcuts
if (-not $NoShortcuts) {
    $cmd     = Join-Path $gameDir 'Fallout_chinese_windowed.cmd'
    $icon    = Join-Path $gameDir 'falloutw.exe'
    $desktop = [Environment]::GetFolderPath('Desktop')
    $sh      = New-Object -ComObject WScript.Shell
    $defs = @(
        @{ name = 'Fallout 中文窗口'; args = '' },
        @{ name = 'Fallout 中文全屏'; args = '-Exclusive' }
    )
    foreach ($d in $defs) {
        $lnkPath = Join-Path $desktop ($d.name + '.lnk')
        $lnk = $sh.CreateShortcut($lnkPath)
        $lnk.TargetPath       = $cmd
        $lnk.Arguments        = $d.args
        $lnk.WorkingDirectory = $gameDir
        $lnk.IconLocation     = $icon + ',0'
        $lnk.WindowStyle      = 7
        $lnk.Description      = 'Fallout (简体中文) 高清'
        $lnk.Save()
        Say ("shortcut: " + $lnkPath)
    }
}

$blockers = Get-Process -Name 'MuMuNxMain', 'MuMuNxDevice', 'dnplayer', 'HD-Player', 'NoxAppPlayer' -ErrorAction SilentlyContinue
if ($blockers) {
    Write-Host ''
    Write-Host '  note: an Android emulator is running. It can grab the DirectInput devices' -ForegroundColor Yellow
    Write-Host '        and make Fallout stop with "Failure initializing input devices."' -ForegroundColor Yellow
    Write-Host '        Close the emulator before playing.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '  done.' -ForegroundColor Green
Write-Host ''
Write-Host '  Start the game with the desktop shortcut "Fallout 中文窗口" (2K window) or'
Write-Host '  "Fallout 中文全屏" (fullscreen).'
Write-Host '  Pressing Play in Steam still works, but only in the safe basic mode'
Write-Host '  (1920x1440 fullscreen), without the hi-res DirectX 9 renderer.'
Write-Host '  Steam "verify integrity of game files" restores the English FALLOUTW.EXE;'
Write-Host '  run install.cmd again afterwards.'
Write-Host ''


