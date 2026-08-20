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
    Invoke-RestMethod  -Uri http://localhost:8090/api/Home/Stop -ErrorAction SilentlyContinue
  } catch {
  }
  Set-Location "./dbproject/ScriptsFolder"
  ./dbdeploy -TargetServerName localhost -TargetODSDBname $ClientDBODSName -TargetLandingDBname $ClientDBLandingName -TargetDWHDBname $ClientDBDWHName -IsApplyScripts $true

     Set-Location $CurrentPath

  try {
    Invoke-RestMethod  -Uri http://localhost:8090/api/Home/Start -ErrorAction SilentlyContinue
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

# ==============================================================================
# ОСНОВНОЙ СКРИПТ ПУСКА
# ==============================================================================

docker compose down -v
#docker compose up

# 1. Запуск docker compose в новом окне для отображения логов
Start-Process "cmd.exe" -ArgumentList "/k docker compose up"

# 2. Пауза (в секундах), чтобы контейнеры успели запуститься до открытия браузера
Start-Sleep -Seconds 15

# 3. Открытие нужной страницы в браузере по умолчанию
Start-Process "http://localhost:8100"
