#Requires -Version 5.1
<#
.SYNOPSIS
  Start WSL (Ubuntu-DWH), Ollama serve without systemd, port forward 11434 on Windows.

.EXAMPLE
  .\start-ollama-wsl.ps1
  .\start-ollama-wsl.ps1 -WslDistro Ubuntu-DWH -SkipPortForward
  .\start-ollama-wsl.ps1 -ForwardOnly
#>
param(
  [string]$WslDistro = "Ubuntu-DWH",
  [int]$Port = 11434,
  [switch]$SkipPortForward,
  [switch]$ForwardOnly,
  [switch]$SkipBrowser
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot

function Test-WslDistro {
  param([string]$Name)
  $list = wsl --list --quiet 2>$null
  if (-not $list) { return $false }
  foreach ($line in $list) {
    $n = $line.Trim() -replace "`0", ""
    if ($n -eq $Name) { return $true }
  }
  return $false
}

if (-not (Test-WslDistro $WslDistro)) {
  Write-Host "Installed distros:" -ForegroundColor Yellow
  wsl --list --verbose
  throw "Distro '$WslDistro' not found. Use -WslDistro."
}

if (-not $ForwardOnly) {
  Write-Host "==> Starting WSL: $WslDistro" -ForegroundColor Cyan
  wsl -d $WslDistro -- true | Out-Null

  $drive = $ScriptDir.Substring(0, 1).ToLower()
  $unixPath = "/mnt/$drive" + ($ScriptDir.Substring(2) -replace '\\', '/')
  $bashScript = "$unixPath/ollama-serve.sh"

  Write-Host '==> Ollama serve (OLLAMA_HOST=0.0.0.0, no systemd)' -ForegroundColor Cyan
  # Strip CRLF from Windows checkout before execute (fixes env: bash\r)
  $startCmd = "sed -i 's/\r$//' '$bashScript'; chmod +x '$bashScript'; '$bashScript'"
  wsl -d $WslDistro -- bash -lc $startCmd
  if ($LASTEXITCODE -ne 0) {
    throw "ollama-serve.sh failed with exit code $LASTEXITCODE"
  }

  Write-Host ""
  Write-Host "Listening in WSL:" -ForegroundColor DarkGray
  $listenCmd = "ss -tlnp 2>/dev/null | grep $Port; netstat -tlnp 2>/dev/null | grep $Port"
  wsl -d $WslDistro -- bash -lc $listenCmd
}

if (-not $SkipPortForward) {
  Write-Host ""
  Write-Host "==> Port forward on Windows (Admin required)..." -ForegroundColor Cyan
  $forwardScript = Join-Path $ScriptDir "forward_ports.ps1"
  $forwardArgs = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", $forwardScript,
    "-WslDistro", $WslDistro,
    "-Port", $Port
  )
  if ($SkipBrowser) { $forwardArgs += "-SkipBrowser" }

  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

  if ($isAdmin) {
    & $forwardScript -WslDistro $WslDistro -Port $Port -SkipBrowser:$SkipBrowser
  }
  else {
    Start-Process powershell.exe -Verb RunAs -ArgumentList $forwardArgs
    Write-Host "[*] Admin window opened for forward_ports.ps1" -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "Done. For k3s Endpoints use Windows LAN IP (ipconfig), not WSL IP." -ForegroundColor Green
