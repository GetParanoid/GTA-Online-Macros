<#
.SYNOPSIS
  Downloads the latest GTA Online Macros from GitHub, updates the local files,
  and reloads gtav_macros.ahk if it is running.

.DESCRIPTION
  - Pins the download to the branch's newest commit, so GitHub's raw-file cache
    can't hand back a stale copy.
  - Only replaces files whose contents changed, keeping a .bak of each one.
  - If the script is running, starts the new copy; the script then closes the
    old one itself (see the single-instance block in gtav_macros.ahk).

.PARAMETER Branch
  Branch to download from. Default: master.

.PARAMETER Start
  Start the script after updating even if it wasn't running.

.PARAMETER NoReload
  Update the files but don't start or reload the script.

.PARAMETER Force
  Inside a git clone, download the files from GitHub instead of using git.
  (By default a git clone is updated with 'git reset --hard HEAD' + 'git pull',
  which discards uncommitted changes to tracked files.)

.PARAMETER NoPause
  Close as soon as the update finishes, without the countdown (for automation).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\update.ps1
#>
[CmdletBinding()]
param(
  [string]$Branch = 'master',
  [switch]$Start,
  [switch]$NoReload,
  [switch]$Force,
  [switch]$NoPause
)

# --- Keep the window open long enough to read the result ---
#     Success: closes after 3 seconds, or sooner on any key. Error: waits for a key.
function Exit-Updater([int]$Code = 0) {
  if (-not $NoPause) {
    try {
      while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) }   # ignore keys pressed earlier
      if ($Code -ne 0) {
        Write-Host 'Press any key to close...'
        [void][Console]::ReadKey($true)
      } else {
        for ($i = 3; $i -gt 0; $i--) {
          Write-Host -NoNewline "`rClosing in $i... (press any key to close now) "
          $until = (Get-Date).AddSeconds(1)
          while ((Get-Date) -lt $until) {
            if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); $i = 0; break }
            Start-Sleep -Milliseconds 50
          }
        }
        Write-Host
      }
    } catch {
      Start-Sleep -Seconds 3   # no interactive console (e.g. ISE or redirected input)
    }
  }
  exit $Code
}

trap {
  Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
  Exit-Updater 1
}

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12   # Windows PowerShell 5.1

$Repo       = 'GetParanoid/GTA-Online-Macros'
$ScriptName = 'gtav_macros.ahk'
$Files      = @($ScriptName, 'README.md', 'update.ps1')
$Dir        = $PSScriptRoot
$ScriptPath = Join-Path $Dir $ScriptName

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

function Invoke-Git {
  & git -C $Dir @args
  if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed (exit code $LASTEXITCODE)." }
}

$UseGit = (Test-Path (Join-Path $Dir '.git')) -and -not $Force

if ($UseGit) {
  # --- Git clone: throw away local changes to tracked files, then pull ---
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "This folder is a git clone but git isn't installed or on PATH. Install git, or rerun with -Force to download the files instead."
  }
  $before = (Invoke-Git rev-parse HEAD | Out-String).Trim()
  Write-Step 'Git clone detected: discarding local changes (git reset --hard HEAD)'
  Invoke-Git reset --hard HEAD
  Write-Step 'Pulling the latest changes (git pull)'
  Invoke-Git pull
  $after = (Invoke-Git rev-parse HEAD | Out-String).Trim()

  $changed = @()
  if ($before -ne $after) {
    $changed = @(Invoke-Git diff --name-only $before $after | Where-Object { $_ })
  }
} else {

# --- Resolve the newest commit (falls back to the branch name) ---
$Ref = $Branch
try {
  $Ref = (Invoke-RestMethod -UseBasicParsing `
          -Uri "https://api.github.com/repos/$Repo/commits/$Branch" `
          -Headers @{ Accept = 'application/vnd.github.sha'; 'User-Agent' = 'gtav-macros-updater' }).Trim()
  Write-Step "Latest commit on ${Branch}: $($Ref.Substring(0, 7))"
} catch {
  Write-Warning "Couldn't look up the latest commit ($($_.Exception.Message)); downloading '$Branch' directly. It may be a few minutes out of date."
}

# --- Download everything to a temp folder first, so a failed download changes nothing ---
$Temp = Join-Path ([IO.Path]::GetTempPath()) ("gtav-macros-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Temp | Out-Null
try {
  $downloaded = @()
  foreach ($f in $Files) {
    Write-Step "Downloading $f"
    try {
      Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/$Repo/$Ref/$f" `
        -OutFile (Join-Path $Temp $f)
      $downloaded += $f
    } catch {
      if ($f -eq $ScriptName) { throw "Couldn't download ${f}: $($_.Exception.Message)" }
      Write-Warning "Skipping $f (not available: $($_.Exception.Message))"
    }
  }

  # --- Replace only files that changed ---
  $changed = @()
  foreach ($f in $downloaded) {
    $new = Join-Path $Temp $f
    $old = Join-Path $Dir $f
    if ((Test-Path $old) -and ((Get-FileHash $old).Hash -eq (Get-FileHash $new).Hash)) { continue }
    if (Test-Path $old) { Copy-Item $old "$old.bak" -Force }
    Copy-Item $new $old -Force
    $changed += $f
  }
} finally {
  Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
}

}   # end download mode

if ($changed.Count -eq 0) {
  Write-Host 'Already up to date.' -ForegroundColor Green
} else {
  Write-Host ("Updated: " + ($changed -join ', ')) -ForegroundColor Green
  if (-not $UseGit) { Write-Host 'Previous versions were saved as .bak files.' }
}

if ($NoReload) { Exit-Updater 0 }

# --- Is the script running? Look for its hidden AutoHotkey window ("<path> - AutoHotkey v...").
#     Window titles are readable even when the script runs as admin and we don't. ---
Add-Type -Namespace Win32 -Name Windows -MemberDefinition @'
  public delegate bool EnumProc(System.IntPtr hWnd, System.IntPtr lParam);
  [System.Runtime.InteropServices.DllImport("user32.dll")]
  public static extern bool EnumWindows(EnumProc cb, System.IntPtr lParam);
  [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
  public static extern int GetWindowText(System.IntPtr hWnd, System.Text.StringBuilder s, int n);
  [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
  public static extern int GetClassName(System.IntPtr hWnd, System.Text.StringBuilder s, int n);
'@

function Test-ScriptRunning([string]$path) {
  $script:found = $false
  $cb = [Win32.Windows+EnumProc]{
    param($h, $l)
    $cls = New-Object Text.StringBuilder 64
    [void][Win32.Windows]::GetClassName($h, $cls, 64)
    if ($cls.ToString() -eq 'AutoHotkey') {
      $title = New-Object Text.StringBuilder 1024
      [void][Win32.Windows]::GetWindowText($h, $title, 1024)
      if ($title.ToString().StartsWith($path, [StringComparison]::OrdinalIgnoreCase)) { $script:found = $true; return $false }
    }
    return $true
  }
  [void][Win32.Windows]::EnumWindows($cb, [IntPtr]::Zero)
  return $script:found
}

$running = Test-ScriptRunning $ScriptPath
if (-not $running -and -not $Start) {
  Write-Host "$ScriptName isn't running, so there's nothing to reload. Use -Start to launch it."
  Exit-Updater 0
}
if ($running -and $changed -notcontains $ScriptName) {
  Write-Host "$ScriptName didn't change; leaving the running copy alone."
  Exit-Updater 0
}

# --- Start the new copy with AutoHotkey v1 (the script won't run under v2) ---
$ahk = Get-ChildItem "$env:ProgramFiles\AutoHotkey\v1.*\AutoHotkeyU64.exe", "$env:ProgramFiles\AutoHotkey\AutoHotkeyU64.exe", "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe" -ErrorAction SilentlyContinue |
       Where-Object { $_.VersionInfo.FileVersion -like '1.*' } |
       Sort-Object { [version]$_.VersionInfo.FileVersion } -Descending |
       Select-Object -First 1

Write-Step $(if ($running) { "Reloading $ScriptName" } else { "Starting $ScriptName" })
if ($ahk) {
  Start-Process -FilePath $ahk.FullName -ArgumentList "`"$ScriptPath`"" -WorkingDirectory $Dir
} else {
  Write-Warning 'AutoHotkey v1 not found in Program Files; opening the script with its default program.'
  Start-Process -FilePath $ScriptPath -WorkingDirectory $Dir
}
Write-Host 'Approve the Administrator prompt if Windows shows one. The new copy closes the old one automatically.' -ForegroundColor Green
Exit-Updater 0
