Param (
    [parameter(Mandatory=$false)][string]$IsUpdate=$false
  )
# todo: put this in a dedicated file for reuse and dot-source the file
function Test-Administrator  
{  
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
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
$error.Clear()
$LASTEXITCODE = 0
$ClientName="nevadwh"
$ClientDBODSName="nevadwh_ods"
$ClientDBDWHName="nevadwh_dwh"
$ClientDBLandingName="nevadwh_landing"
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
"CREATE SERVER client_ods FOREIGN DATA WRAPPER postgres_fdw OPTIONS (dbname 'nevadwh_ods', host '127.0.0.1', port '5432');`r`n" | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
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
docker compose down -v
docker compose up
