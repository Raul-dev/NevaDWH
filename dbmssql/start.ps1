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
