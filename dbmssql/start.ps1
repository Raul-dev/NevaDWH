Param (
  [parameter(Mandatory=$false)][string]$IsUpdate=$false
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
    Invoke-RestMethod  -Uri http://localhost:8090/api/Home/Stop -ErrorAction SilentlyContinue
  } catch {
  }
}
.\dbdeploy.ps1 -TargetServerName localhost -TargetLogDBname "NevaDWH-DEMO_log" -TargetODSDBname "NevaDWH-DEMO_ods" -TargetLandingDBname "NevaDWH-DEMO_landing" -TargetDWHDBname "NevaDWH-DEMO_dwh" -PublishOnly -IsRebuild
if ($LASTEXITCODE -ne 0)
{
  Set-Location $CurrentPath

  exit
}
$res = MergeUser NevaDWH-DEMO_log localhost "NevaDWH-DEMOuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
  throw "Create log user NevaDWH-DEMOuser failed."
}
$res = MergeUser NevaDWH-DEMO_ods localhost "NevaDWH-DEMOuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
  throw "Create user NevaDWH-DEMOuser failed."
}
$res = MergeUser NevaDWH-DEMO_landing localhost "NevaDWH-DEMOuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
  throw "Create landing user NevaDWH-DEMOuser failed."
}
$res = MergeUser NevaDWH-DEMO_dwh localhost "NevaDWH-DEMOuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
  throw "Create dwh user NevaDWH-DEMOuser failed."
}
Set-Location $CurrentPath

if($IsUpdate -eq $true){
  try{
    Invoke-RestMethod  -Uri http://localhost:8090/api/Home/Start -ErrorAction SilentlyContinue
  } catch {
  }
  exit
}
$Shares = Get-SMBShare -name "Upload" -erroraction 'silentlycontinue'
if($Shares){
  Remove-SmbShare -name "Upload" -Force
}
$serverName = 'HOMEST'
$sharePath = 'Upload' # you can append more paths here
if( Test-Connection $serverName 2> $null ){
  if( -not (Test-Path "\\${serverName}\${sharePath}")){
    $everyoneSID = [System.Security.Principal.SecurityIdentifier]::new('S-1-1-0')
    $everyoneName = $everyoneSID.Translate([System.Security.Principal.NTAccount]).Value
    Write-Host $everyoneName
    $SharetPath = Join-Path -Path $CurrentPath -ChildPath  "Upload"
    Write-Host $SharetPath
    if( -not (Test-Path $SharetPath)){
      New-Item -Path $CurrentPath -Name "Upload" -ItemType "directory"
    }
    New-SmbShare -Name "Upload" -Path $SharetPath -FullAccess $everyoneName
  }
}

Set-Location $CurrentPath
docker compose up
