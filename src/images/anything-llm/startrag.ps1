#Requires -Version 5.1
<#
.SYNOPSIS
  Podnyat Ollama (WSL ili Docker) i prognat NevaRagEval po eval-questions.md.

.PARAMETER Ollama
  wsl | docker

.PARAMETER Corpus
  portal | engineer | both

.EXAMPLE
  .\startrag.ps1
  .\startrag.ps1 -Ollama docker
  .\startrag.ps1 -Corpus engineer
  .\startrag.ps1 -Corpus portal -ScenarioId 2
#>
param(
  [ValidateSet("wsl", "docker")]
  [string]$Ollama = "wsl",

  [ValidateSet("portal", "engineer", "both")]
  [string]$Corpus = "portal",

  [string]$WslDistro = "Ubuntu-DWH",
  [int]$Port = 11434,
  [string]$OllamaUrl = "http://127.0.0.1:11434",
  [string]$DockerImage = "nevaaichat-ollama",
  [string]$DockerContainer = "nevaaichat-ollama-eval",
  [int]$ReadyTimeoutSec = 300,
  [int]$ScenarioId = 0,
  [switch]$SkipEval,
  [switch]$SkipBrowser
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$RagRoot = Join-Path $ScriptDir "rag"
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
$StartWslScript = Join-Path $ScriptDir "..\ollama\start-ollama-wsl.ps1"
$ComposeFile = Join-Path $RepoRoot "docker-compose-WebAI.yml"

function Write-Step([string]$Message) {
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-OllamaReady {
  param([string]$BaseUrl, [int]$TimeoutSec = 5)
  try {
    $uri = ($BaseUrl.TrimEnd("/") + "/api/tags")
    $resp = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec $TimeoutSec
    return $null -ne $resp
  }
  catch {
    return $false
  }
}

function Wait-OllamaReady {
  param(
    [string]$BaseUrl,
    [int]$TimeoutSec,
    [string]$Label
  )
  Write-Step "Waiting for Ollama ($Label) at $BaseUrl ..."
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if (Test-OllamaReady -BaseUrl $BaseUrl) {
      Write-Host "[+] Ollama ready" -ForegroundColor Green
      return
    }
    Start-Sleep -Seconds 3
    Write-Host "." -NoNewline
  }
  Write-Host ""
  throw "Ollama not ready within ${TimeoutSec}s at $BaseUrl"
}

function Stop-WslOllama {
  param([string]$Distro, [int]$ListenPort)
  Write-Step "Stopping WSL Ollama ($Distro)"
  $killCmd = @'
pkill -f 'ollama serve' 2>/dev/null || true
if [ -f /tmp/ollama-serve.pid ]; then kill $(cat /tmp/ollama-serve.pid) 2>/dev/null || true; rm -f /tmp/ollama-serve.pid; fi
'@
  wsl -d $Distro -- bash -lc $killCmd 2>$null | Out-Null

  netsh interface portproxy delete v4tov4 listenport=$ListenPort listenaddress=127.0.0.1 2>$null | Out-Null
  netsh interface portproxy delete v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 2>$null | Out-Null
}

function Stop-DockerOllamaEval {
  param([string]$Name)
  $prev = $ErrorActionPreference
  $ErrorActionPreference = "SilentlyContinue"
  try {
    docker rm -f $Name 2>$null | Out-Null
  }
  finally {
    $ErrorActionPreference = $prev
  }
}

function Ensure-DockerImage {
  param([string]$Image, [string]$Compose)
  docker image inspect $Image 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { return }
  Write-Step "Image $Image not found - building via docker compose"
  if (-not (Test-Path $Compose)) {
    throw "Compose file not found: $Compose"
  }
  docker compose -f $Compose build ollama
  if ($LASTEXITCODE -ne 0) { throw "docker compose build ollama failed" }
}

function Start-DockerOllamaWindow {
  param(
    [string]$Image,
    [string]$Name,
    [int]$ListenPort
  )
  Ensure-DockerImage -Image $Image -Compose $ComposeFile
  Stop-DockerOllamaEval -Name $Name

  $initModels = "llama3.2:1b=llama3 qwen2.5:1.5b=qwen2.5"
  $dockerRun = (
    "Write-Host 'Docker Ollama ($Name) - Ctrl+C to stop' -ForegroundColor Cyan; " +
    "docker rm -f $Name 2>`$null; " +
    "docker run --name $Name -p ${ListenPort}:11434 -e OLLAMA_HOST=0.0.0.0:11434 -e OLLAMA_INIT_MODELS='$initModels' $Image"
  )

  Write-Step "Starting Docker Ollama in new window (image: $Image)"
  Start-Process powershell.exe -ArgumentList @(
    "-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $dockerRun
  )
}

function Start-WslOllamaIfNeeded {
  if (Test-OllamaReady -BaseUrl $OllamaUrl) {
    Write-Host "[+] WSL Ollama already up at $OllamaUrl" -ForegroundColor Green
    return
  }

  if (-not (Test-Path $StartWslScript)) {
    throw "start-ollama-wsl.ps1 not found: $StartWslScript"
  }

  Write-Step "Starting WSL Ollama via start-ollama-wsl.ps1"
  & $StartWslScript -WslDistro $WslDistro -Port $Port -SkipBrowser:$SkipBrowser
  if ($LASTEXITCODE -ne 0) { throw "start-ollama-wsl.ps1 failed" }

  Wait-OllamaReady -BaseUrl $OllamaUrl -TimeoutSec $ReadyTimeoutSec -Label "WSL"
}

function Invoke-RagEval {
  param(
    [string]$EvalCorpus,
    [string]$Model,
    [string]$BaseUrl,
    [int]$Id
  )
  Write-Step "NevaRagEval corpus=$EvalCorpus model=$Model"
  Push-Location $ScriptDir
  try {
    $dotnetArgs = @(
      "run", "--project", "NevaRagEval", "--",
      "--corpus", $EvalCorpus,
      "--model", $Model,
      "--ollama", $BaseUrl,
      "--rag-root", $RagRoot
    )
    if ($Id -gt 0) {
      $dotnetArgs += @("--id", "$Id")
    }
    dotnet @dotnetArgs
    if ($LASTEXITCODE -ne 0) {
      throw "NevaRagEval failed for corpus $EvalCorpus (exit $LASTEXITCODE)"
    }
  }
  finally {
    Pop-Location
  }
}

Write-Host ""
Write-Host "Neva RAG eval runner (Ollama=$Ollama, corpus=$Corpus)" -ForegroundColor White
Write-Host ""

switch ($Ollama) {
  "wsl" {
    Stop-DockerOllamaEval -Name $DockerContainer
    Start-WslOllamaIfNeeded
  }
  "docker" {
    Stop-WslOllama -Distro $WslDistro -ListenPort $Port
    Start-DockerOllamaWindow -Image $DockerImage -Name $DockerContainer -ListenPort $Port
    Wait-OllamaReady -BaseUrl $OllamaUrl -TimeoutSec $ReadyTimeoutSec -Label "Docker"
  }
}

if ($SkipEval) {
  Write-Host "SkipEval - Ollama ready, tests skipped." -ForegroundColor Yellow
  exit 0
}

$fail = $false
if ($Corpus -eq "both") {
  try { Invoke-RagEval -EvalCorpus "portal" -Model "llama3" -BaseUrl $OllamaUrl -Id $ScenarioId }
  catch { $fail = $true; Write-Host $_.Exception.Message -ForegroundColor Red }
  try { Invoke-RagEval -EvalCorpus "engineer" -Model "qwen2.5" -BaseUrl $OllamaUrl -Id $ScenarioId }
  catch { $fail = $true; Write-Host $_.Exception.Message -ForegroundColor Red }
}
else {
  $model = if ($Corpus -eq "engineer") { "qwen2.5" } else { "llama3" }
  try { Invoke-RagEval -EvalCorpus $Corpus -Model $model -BaseUrl $OllamaUrl -Id $ScenarioId }
  catch { $fail = $true; Write-Host $_.Exception.Message -ForegroundColor Red }
}

if ($fail) { exit 3 }
Write-Host ""
Write-Host "Done." -ForegroundColor Green
