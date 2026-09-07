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


$ErrorActionPreference = "Stop";
$CurrentPath = Get-Location
Set-Location "./dbproject/ScriptsFolder"
$error.Clear()
$LASTEXITCODE = 0
$ClientName="newadwh"
$ClientDBODSName="newadwh_ods"
$ClientDBDWHName="newadwh_dwh"
$ClientDBLandingName="newadwh_landing"
./dbdeploy -TargetServerName localhost -TargetODSDBname $ClientDBODSName -TargetLandingDBname $ClientDBLandingName -TargetDWHDBname $ClientDBDWHName -IsApplyScripts $false
if ($LASTEXITCODE -eq -1)
{
  exit
}
Set-Location $CurrentPath
$SqlScript = ("DROP DATABASE IF EXISTS $ClientDBODSName;",
"DROP DATABASE IF EXISTS $ClientDBDWHName;",
"DROP DATABASE IF EXISTS $ClientDBLandingName;",
"CREATE DATABASE $ClientDBODSName ;",
"\c $ClientDBODSName;",
"CREATE DATABASE $ClientDBLandingName ;",
"\c $ClientDBLandingName;",
"CREATE USER db_owner PASSWORD 'db_owner';",
"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_owner;",
"CREATE DATABASE $ClientDBDWHName ;",
"\c $ClientDBDWHName;")

$OutputDumpFile ="005_create_db.sql"
Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue
$SqlScript | Out-String | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
$SqlFile = $CurrentPath.ToString()+"/dbproject/ScriptsFolder/create_ods.sql"
$OutputDumpFile ="010_create_ods.sql"
Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue
"\c $ClientDBODSName;`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
Get-Content -Encoding "UTF8" $SqlFile | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
$SqlFile = $CurrentPath.ToString()+"/dbproject/ScriptsFolder/dictionaries_ods.sql"
$OutputDumpFile ="020_dictionaries_ods.sql"
Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue
"\c $ClientDBODSName;`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
Get-Content -Encoding "UTF8" $SqlFile | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append

# dwh
$SqlFile = $CurrentPath.ToString()+"/dbproject/ScriptsFolder/create_dwh.sql"
$OutputDumpFile ="030_create_dwh.sql"
Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue
"\c $ClientDBDWHName;`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
"CREATE extension postgres_fdw;`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
"CREATE SERVER client_ods FOREIGN DATA WRAPPER postgres_fdw OPTIONS (dbname 'newadwh_ods', host '127.0.0.1', port '5432');`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
"CREATE USER MAPPING FOR postgres SERVER client_ods OPTIONS ( USER 'postgres', PASSWORD 'postgres');`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
Get-Content -Encoding "UTF8" $SqlFile | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
#"SELECT 2;" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
$SqlFile = $CurrentPath.ToString()+"/dbproject/ScriptsFolder/dictionaries_dwh.sql"
$OutputDumpFile ="040_dictionaries_dwh.sql"
Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue
"\c $ClientDBDWHName;`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append

Get-Content -Encoding "UTF8" $SqlFile | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
#"SELECT 1;" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append

# Landing
$SqlFile = $CurrentPath.ToString()+"/dbproject/ScriptsFolder/create_landing.sql"
$OutputDumpFile ="050_create_landing.sql"
Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue
"\c $ClientDBLandingName;`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
Get-Content -Encoding "UTF8" $SqlFile | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
$SqlFile = $CurrentPath.ToString()+"/dbproject/ScriptsFolder/dictionaries_landing.sql"
$OutputDumpFile ="060_dictionaries_landing.sql"
Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue
"\c $ClientDBLandingName;`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
Get-Content -Encoding "UTF8" $SqlFile | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append

if($IsUpdate -eq $true){
  try {
    Invoke-RestMethod -Method Post -Uri http://localhost:8090/v1/mq/service/stop -ErrorAction SilentlyContinue
  } catch {
  }
  Set-Location "./dbproject/ScriptsFolder"
  ./dbdeploy -TargetServerName localhost -TargetODSDBname $ClientDBODSName -TargetLandingDBname $ClientDBLandingName -TargetDWHDBname $ClientDBDWHName -IsApplyScripts $true

     Set-Location $CurrentPath

  try {
    Invoke-RestMethod -Method Post -Uri http://localhost:8090/v1/mq/service/start -ErrorAction SilentlyContinue
  } catch {
  }
  exit
}

$Shares = Get-SMBShare -name "Upload" -erroraction 'silentlycontinue'
if (Test-Administrator) {
  if($Shares){
    Remove-SmbShare -name "Upload" -Force
  }
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
$utf8bom = [System.Text.UTF8Encoding]::new($true)
[Console]::OutputEncoding = $utf8bom
$OutputEncoding = $utf8bom
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

function Invoke-PsqlFileIntoContainer {
  param([string]$Container, [string]$Database, [string]$FilePath)
  Write-Host "Applying $FilePath to $Database..." -ForegroundColor Cyan
  $sql = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
  $sql = $sql -replace '(?m)^\\c\s+\S+;\s*', ''
  $sql | docker exec -i $Container psql -U postgres -d $Database -v ON_ERROR_STOP=1
  if ($LASTEXITCODE -ne 0) { throw "psql failed: $FilePath -> $Database" }
}

function Ensure-PsqlClientSchemas {
  $container = 'client-postgresdb17'
  for ($i = 0; $i -lt 90; $i++) {
    docker exec $container pg_isready -U postgres 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 2
  }
  $landingOk = docker exec $container psql -U postgres -d $ClientDBLandingName -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='mq' AND table_name='metamap'" 2>$null
  if (($landingOk | Out-String).Trim() -ne '1') {
    Write-Host "Landing schema missing; applying 050/060..." -ForegroundColor Yellow
    Invoke-PsqlFileIntoContainer $container $ClientDBLandingName '050_create_landing.sql'
    Invoke-PsqlFileIntoContainer $container $ClientDBLandingName '060_dictionaries_landing.sql'
  } else {
    Write-Host "Landing schema already present." -ForegroundColor Green
  }
  $dwhSrc = docker exec $container psql -U postgres -d $ClientDBDWHName -tAc "SELECT 1 FROM mq.data_source LIMIT 1" 2>$null
  if (($dwhSrc | Out-String).Trim() -ne '1') {
    Write-Host "DWH dictionaries missing; applying 040..." -ForegroundColor Yellow
    Invoke-PsqlFileIntoContainer $container $ClientDBDWHName '040_dictionaries_dwh.sql'
  }
}

# ==============================================================================
# ОСНОВНОЙ СКРИПТ ПУСКА
# ==============================================================================

Test-Port80Available

# 1. Запуск docker compose в новом окне для отображения логов
Start-Process "cmd.exe" -ArgumentList "/k docker compose up"

# 2. Сборка из исходников дольше, чем hub-образы: ждём админку, иначе Traefik отдаёт 404
Write-Host "Ожидание http://localhost/ (NevadWH за Traefik)..." -ForegroundColor Cyan
$ready = $false
for ($i = 0; $i -lt 90; $i++) {
  try {
    $resp = Invoke-WebRequest -Uri "http://localhost/" -MaximumRedirection 0 -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
    if ($resp.StatusCode -ne 404) { $ready = $true; break }
  } catch {
    $code = 0
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    if ($code -gt 0 -and $code -ne 404) { $ready = $true; break }
  }
  Start-Sleep -Seconds 2
}
if ($ready) {
  Write-Host "Админка отвечает." -ForegroundColor Green
} else {
  Write-Host "Админка ещё не ответила. Проверьте окно docker compose (mq/landing/nevadwh не в статусе Created)." -ForegroundColor Yellow
}

# Init SQL runs only on an empty volume. If 040 failed, 050/060 never ran — apply them now.
Ensure-PsqlClientSchemas

# 3. Открытие нужной страницы в браузере по умолчанию
Start-Process "http://localhost/"
