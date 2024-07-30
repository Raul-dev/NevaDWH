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
    try
    {
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
./dbdeploy -TargetServerName localhost -TargetODSDBname "nevadwh_ods" -TargetLandingDBname "nevadwh_landing" -TargetDWHDBname "nevadwh_dwh" -PublishOnly $true -IsRebuild $true
if ($LASTEXITCODE -eq -1)
{
  Set-Location $CurrentPath

  exit
}
$res = MergeUser nevadwh_ods localhost "nevadwhuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
    throw "Create user nevadwhuser failed."
}
$res = MergeUser nevadwh_landing localhost "nevadwhuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
    throw "Create landing user nevadwhuser failed."
}
$res = MergeUser nevadwh_dwh localhost "nevadwhuser" "MyPassword321"
IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
    throw "Create dwh user nevadwhuser failed."
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
