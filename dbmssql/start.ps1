Param (
  [Parameter(Mandatory=$false)][string]$IsUpdate=$false,
  [Parameter(Mandatory = $false)][string]$ServerName = 'localhost'
)
function Test-Administrator  
{  
  [OutputType([bool])]
  param()
  process {
    [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
    return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
  }
}

function MergeUser
{
  Param (
  [string]$lTargetDBname,
  [string]$lTargetServerName,
  [string]$lSQLuser,
  [string]$lSQLpwd
  )
  try{
    $lSqlCmd = "
      IF SUSER_ID('"+$lSQLuser+"') IS NULL
        CREATE LOGIN ["+$lSQLuser+"] WITH PASSWORD = N'"+$lSQLpwd+"', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
      
      IF USER_ID('"+$lSQLuser+"') IS NULL
        CREATE USER ["+$lSQLuser+"] FOR LOGIN ["+$lSQLuser+"] WITH DEFAULT_SCHEMA=[dbo]
      ALTER ROLE db_owner ADD MEMBER ["+$lSQLuser+"];
      "
    sqlcmd -S $lTargetServerName  -d $lTargetDBname -Q $lSqlCmd
    return 0
  }
  catch {
    Write-Host "An error occurred:" -fore red
    Write-Host $_ -fore red
    return -1
  }
}

function Test-Port80Available
{
  Write-Host "Проверка порта 80 (Traefik)..." -ForegroundColor Cyan
  $listeners = @()
  try {
    $listeners = @(Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue |
      Sort-Object -Property OwningProcess -Unique)
  } catch {
    $listeners = @()
  }
  if ($listeners.Count -eq 0) {
    Write-Host "Порт 80 свободен." -ForegroundColor Green
    return
  }

  $cwd = (Get-Location).Path.TrimEnd('\')
  $thisStackHoldsPort = $false
  $dockerHolders = @()
  $ids = @()
  try {
    $ids = @(docker ps --filter "publish=80" -q 2>$null)
  } catch {
    $ids = @()
  }
  foreach ($id in $ids) {
    if ([string]::IsNullOrWhiteSpace($id)) { continue }
    $info = $null
    try {
      $raw = docker inspect $id | ConvertFrom-Json
      $info = @($raw)[0]
    } catch {
      continue
    }
    if (-not $info) { continue }
    $name = ([string]$info.Name).TrimStart('/')
    $workdir = $null
    try {
      $workdir = $info.Config.Labels.'com.docker.compose.project.working_dir'
    } catch { }
    $dockerHolders += [pscustomobject]@{ Name = $name; Id = $id; WorkDir = $workdir }
    if ($workdir -and ($workdir.TrimEnd('\') -eq $cwd)) {
      $thisStackHoldsPort = $true
    }
  }

  if ($thisStackHoldsPort) {
    Write-Host "Порт 80 уже слушает Traefik этого стенда — compose его пересоздаст." -ForegroundColor DarkGray
    return
  }

  Write-Host "Порт 80 занят. Traefik не сможет поднять http://localhost/" -ForegroundColor Red
  foreach ($l in $listeners) {
    $procId = $l.OwningProcess
    $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
    $procName = if ($proc) { $proc.ProcessName } else { '?' }
    $exe = $null
    try {
      $exe = (Get-CimInstance Win32_Process -Filter "ProcessId=$procId" -ErrorAction SilentlyContinue).ExecutablePath
    } catch { }
    Write-Host ("  PID={0}  Name={1}  Path={2}  Bind={3}" -f $procId, $procName, $exe, $l.LocalAddress) -ForegroundColor Yellow
  }
  if ($dockerHolders.Count -gt 0) {
    Write-Host "  Docker-контейнеры с publish 80:" -ForegroundColor Yellow
    foreach ($h in $dockerHolders) {
      Write-Host ("    {0}  ({1})" -f $h.Name, $h.WorkDir) -ForegroundColor Yellow
    }
  }

  Write-Host ""
  Write-Host "Как освободить порт 80:" -ForegroundColor Cyan
  Write-Host "  1) Другой Docker-стек (часто Traefik из docker-compose-price.yml / docker-compose.yml):"
  Write-Host "       docker ps --filter publish=80"
  Write-Host "       docker stop <имя_контейнера>"
  Write-Host "       или в том каталоге: docker compose down"
  Write-Host "  2) IIS (W3SVC, часто PID=4 System / HTTP.sys):"
  Write-Host "       net stop w3svc"
  Write-Host "       net stop was /y"
  Write-Host "  3) Произвольный процесс:"
  Write-Host "       Stop-Process -Id <PID> -Force"
  Write-Host "  4) Резерв URL в HTTP.sys:"
  Write-Host "       netsh http show urlacl"
  Write-Host "       netsh http show servicestate view=requestq"
  exit 1
}

if(-not $IsUpdate) {
  if(-not (Test-Administrator))
  {
    # TODO: define proper exit codes for the given errors 
    Write-Error "This script must be executed as Administrator.";
    exit 1;
  }
}

$ErrorActionPreference = "Stop";
$CurrentPath = Get-Location
Set-Location "./dbproject/ScriptsFolder"
if($IsUpdate -eq $true){
  try{
    Invoke-RestMethod -Method Post -Uri http://localhost:8090/v1/mq/service/stop -ErrorAction SilentlyContinue
  } catch {
  }
}
.\dbdeploy.ps1 -TargetServerName localhost -PublishOnly -IsRebuild
if ($LASTEXITCODE -ne 0)
{
  Set-Location $CurrentPath

  exit
}
$res = MergeUser newadwh_log localhost "newadwhuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
  throw "Create log user newadwhuser failed."
}
$res = MergeUser newadwh_ods localhost "newadwhuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0) {
  throw "Create user newadwhuser on newadwh_ods failed."
}
$res = MergeUser newadwh_landing localhost "newadwhuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0) {
  throw "Create user newadwhuser on newadwh_landing failed."
}
$res = MergeUser newadwh_dwh localhost "newadwhuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0) {
  throw "Create user newadwhuser on newadwh_dwh failed."
}
Set-Location $CurrentPath

if($IsUpdate -eq $true){
  try{
    Invoke-RestMethod -Method Post -Uri http://localhost:8090/v1/mq/service/start -ErrorAction SilentlyContinue
  } catch {
  }
  exit
}
$Shares = Get-SMBShare -name "Upload" -erroraction 'silentlycontinue'
if($Shares){
  Remove-SmbShare -name "Upload" -Force
}
$sharePath = 'Upload' # you can append more paths here
if ($ServerName -in @('localhost', '127.0.0.1', '.')) {
    $ServerName = $env:COMPUTERNAME
    # Альтернативный вариант для получения полного FQDN-имени (с доменом):
    # $ServerName = [System.Net.Dns]::GetHostEntry('').HostName
}
Write-Host "Работаем с сервером: $ServerName"
if (-not (Test-Connection $ServerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
    Write-Host "Сервер $ServerName недоступен."
} else {
  if( -not (Test-Path "\\${ServerName}\${sharePath}")){
    $everyoneSID = [System.Security.Principal.SecurityIdentifier]::new('S-1-1-0')
    $everyoneName = $everyoneSID.Translate([System.Security.Principal.NTAccount]).Value
    Write-Host $everyoneName
    $SharetPath = Join-Path -Path $CurrentPath -ChildPath  "Upload"
    Write-Host $SharetPath
    if( -not (Test-Path $SharetPath)){
      New-Item -Path $CurrentPath -Name "Upload" -ItemType "directory"
    }
    if (Test-Administrator) {
      New-SmbShare -Name "Upload" -Path $SharetPath -FullAccess $everyoneName
    } else {
      Write-Warning "Can't create upload share. This script must be executed as Administrator.";
    }
  }
}

Set-Location $CurrentPath
# ==============================================================================
# ПРОВЕРКА И ПЕРЕЗАПУСК DOCKER (ЕСЛИ СВЯЗЬ СЛОМАНА)
# ==============================================================================

Write-Host "Проверка связи с Docker..." -ForegroundColor Cyan

# Проверяем, отвечает ли Docker-демон
$dockerCheck = docker ps 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Ошибка: Связь с Docker потеряна (канал закрыт)." -ForegroundColor Red
    Write-Host "Попытка перезапуска служб Docker..." -ForegroundColor Yellow

    # Принудительно перезапускаем все службы Windows, связанные с Docker
    Restart-Service *docker* -Force

    # Ждем, пока Docker полностью поднимется (обычно требуется время)
    Write-Host "Ожидание запуска Docker-демона (30 секунд)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Вторая проверка после перезапуска
    docker info > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Критическая ошибка: Не удалось восстановить связь с Docker." -ForegroundColor Red
        Write-Host "Пожалуйста, перезапустите Docker Desktop вручную." -ForegroundColor Red
        Read-Host "Нажмите Enter для выхода..."
        exit
    }
    Write-Host "Связь с Docker успешно восстановлена!" -ForegroundColor Green
} else {
    Write-Host "Docker работает нормально, продолжаем..." -ForegroundColor Green
}

# ==============================================================================
# ОСНОВНОЙ СКРИПТ ПУСКА
# ==============================================================================

Test-Port80Available

# 1. Запуск docker compose в новом окне для отображения логов
Start-Process "cmd.exe" -ArgumentList "/k docker compose up"

# 2. Пауза (в секундах), чтобы контейнеры успели запуститься до открытия браузера
Start-Sleep -Seconds 15

# 3. Открытие нужной страницы в браузере по умолчанию
Start-Process "http://localhost/"
