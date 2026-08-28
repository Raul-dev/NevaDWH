#Requires -Version 5.1
<#
.SYNOPSIS
  Проброс TCP/11434 с Windows (0.0.0.0) в WSL2 + правило Firewall.

.DESCRIPTION
  WSL2 за NAT: с других машин (192.168.0.X, k3s) Ollama доступна только через
  LAN IP Windows-хоста (например 192.168.0.72), не через IP из `hostname -I` внутри WSL.

  Запускать от имени Администратора после старта ollama в WSL.
#>
param(
  [string]$WslDistro = "Ubuntu-DWH",
  [int]$Port = 11434,
  [switch]$SkipBrowser
)

$ErrorActionPreference = "Stop"

function Test-IsAdmin {
  $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-LanIPv4 {
  Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
      $_.IPAddress -notlike "127.*" -and
      $_.IPAddress -notlike "169.254.*" -and
      $_.PrefixOrigin -ne "WellKnown"
    } |
    Select-Object -ExpandProperty IPAddress
}

if (-not (Test-IsAdmin)) {
  Write-Host "[!] Нужны права Администратора (portproxy + firewall)." -ForegroundColor Yellow
  $args = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", $PSCommandPath,
    "-WslDistro", $WslDistro,
    "-Port", $Port
  )
  if ($SkipBrowser) { $args += "-SkipBrowser" }
  Start-Process powershell.exe -Verb RunAs -ArgumentList $args
  exit 0
}

Write-Host ('==> WSL distro: {0}, port: {1}' -f $WslDistro, $Port) -ForegroundColor Cyan

# Запускаем дистрибутив, если выключен
wsl -d $WslDistro -- true | Out-Null

$rawIp = (wsl -d $WslDistro -- hostname -I 2>$null)
if ([string]::IsNullOrWhiteSpace($rawIp)) {
  throw "Не удалось получить IP WSL. Проверьте: wsl -d $WslDistro -- hostname -I"
}
$wslIp = $rawIp.Trim().Split(" ", [StringSplitOptions]::RemoveEmptyEntries)[0]
Write-Host "[*] IP WSL2: $wslIp" -ForegroundColor Cyan

# Ollama health check inside WSL
$checkCmd = "curl -sf http://127.0.0.1:${Port}/ >/dev/null; echo exit:`$?"
$wslCheck = wsl -d $WslDistro -- bash -lc $checkCmd
if ($wslCheck -notmatch 'exit:0') {
  Write-Warning "Ollama not responding on 127.0.0.1:${Port}. Run .\start-ollama-wsl.ps1 first."
}

# Удаляем старые правила portproxy для этого порта
netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=0.0.0.0 2>$null | Out-Null
netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=127.0.0.1 2>$null | Out-Null

netsh interface portproxy add v4tov4 listenport=$Port listenaddress=0.0.0.0 connectport=$Port connectaddress=$wslIp | Out-Null
netsh interface portproxy add v4tov4 listenport=$Port listenaddress=127.0.0.1 connectport=$Port connectaddress=$wslIp | Out-Null

Write-Host "[+] portproxy: 0.0.0.0:${Port} -> ${wslIp}:${Port}" -ForegroundColor Green
Write-Host "[+] portproxy: 127.0.0.1:${Port} -> ${wslIp}:${Port}" -ForegroundColor Green

$fwName = "Ollama API WSL2 ($Port)"
$existing = Get-NetFirewallRule -DisplayName $fwName -ErrorAction SilentlyContinue
if (-not $existing) {
  New-NetFirewallRule -DisplayName $fwName `
    -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port `
    -Profile Any `
    -Description "Доступ к Ollama в WSL2 (portproxy с LAN)" | Out-Null
  Write-Host "[+] Firewall: правило '$fwName' создано" -ForegroundColor Green
} else {
  Write-Host "[*] Firewall: правило '$fwName' уже есть" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Проверка с Windows:" -ForegroundColor Cyan
try {
  $r = Invoke-WebRequest -Uri "http://127.0.0.1:${Port}/" -UseBasicParsing -TimeoutSec 5
  Write-Host "  http://127.0.0.1:${Port}/ -> $($r.StatusCode) $($r.Content.Trim())" -ForegroundColor Green
} catch {
  Write-Warning "  http://127.0.0.1:${Port}/ недоступен: $($_.Exception.Message)"
}

$lanIps = @(Get-LanIPv4)
if ($lanIps.Count -gt 0) {
  Write-Host ""
  Write-Host "С LAN / k3s используйте IP Windows (не IP WSL):" -ForegroundColor Cyan
  foreach ($ip in $lanIps) {
    Write-Host "  http://${ip}:${Port}/" -ForegroundColor Yellow
    try {
      $r2 = Invoke-WebRequest -Uri "http://${ip}:${Port}/" -UseBasicParsing -TimeoutSec 5
      Write-Host "    -> $($r2.StatusCode) OK" -ForegroundColor Green
    } catch {
      Write-Host "    -> недоступен (проверьте сеть/антивирус)" -ForegroundColor DarkYellow
    }
  }
} else {
  Write-Warning "LAN IPv4 не найден (ipconfig)."
}

Write-Host ""
Write-Host "Текущий portproxy:" -ForegroundColor DarkGray
netsh interface portproxy show v4tov4 | Select-String $Port

if (-not $SkipBrowser) {
  Start-Process "http://127.0.0.1:${Port}/"
}
