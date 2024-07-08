#./dbdeploy -TargetServerName localhost -TargetODSDBname "ods_uts" -TargetDWHDBname "dwh_uts"
Param (
    [parameter(Mandatory=$false)][string]$TargetServerName="localhost",
    [parameter(Mandatory=$false)][string]$TargetODSDBname="ods_uts_tmp", 
    [parameter(Mandatory=$false)][string]$TargetLandingDBname="landing_uts_tmp",
    [parameter(Mandatory=$false)][string]$TargetDWHDBname="dwh_uts_tmp", 
    [parameter(Mandatory=$false)][bool]$PublishOnly=$false,
    [parameter(Mandatory=$false)][bool]$IsRebuild=$false,
    [parameter(Mandatory=$false)][string]$SqlPassword=""
  )

Import-Module -Name './MSqlDeploymentFunc.psm1' -Verbose  
$Projectpath = Convert-Path ..
$ExitCode = 0
$VSProjectName = "ods"
try{

    $IsVS2019only = $false
    $obj= Get-MSVsInfo $IsVS2019only
    if($null -eq $obj) {
        Write-Host "Install visual studio first from https://visualstudio.microsoft.com/vs/community/"
        break
    }
    $vsLocation = $obj.InstallationPath
    Write-Host "Visual Studio Location:"
    Write-Host $vsLocation
            
    $devenv = $obj.InstallationPath + "\Common7\IDE\devenv.exe"
    $msbuildLocation = Get-MsBuildPath $IsVS2019only
    if($null -eq $msbuildLocation) {
        Write-Host "MSbuild not found"
        break
    }
    
    Write-Host "Visual Studio msbuild Location:"
    Write-Host $msbuildLocation
    do {
        $Project=$VSProjectName+".sqlproj"
        Set-Location -Path $Projectpath"\"$VSProjectName

        if($VSProjectName -eq "ods"){
            $TargetDBname = $TargetODSDBname
        } elseif ($VSProjectName -eq "landing"){
            $TargetDBname = $TargetLandingDBname
        }  else {
            $TargetDBname = $TargetDWHDBname
        }
        Write-Host ""
        Write-Host "=========================================================" -foregroundcolor green
        Write-Host "Database: "$TargetDBname" Deployment" -foregroundcolor green
        Write-Host "DB Server: "$TargetServerName -foregroundcolor green
        Write-Host "=========================================================" -foregroundcolor green
    
        $Projectname = $VSProjectName #$Project.Split(".")[0]
        $sourceFile =$Projectpath+"\"+$VSProjectName+"\bin\Release\"+$Projectname+".dacpac"

        if (!(Test-Path $sourceFile) -or !($PublishOnly) -or ($IsRebuild)) {

            Write-Host "Start BUILD "$VSProjectName
            Write-Host " -t:rebuild -p:WarningLevel=0 -p:NoWarn='71502, 71558' -p:Configuration=Release "$Project

            #-p:NoWarn='71502 71558' did not work
            & "$msbuildLocation" -t:rebuild -p:WarningLevel=0 -p:Configuration=Release $Project
    
            IF ($LASTEXITCODE -ne 0){
                throw "Build failed."
            }
    
            IF($PublishOnly -eq $false) {
                $res = DropDatabase $TargetDBname $TargetServerName $SQLuser $SQLpwd
                IF ($LASTEXITCODE -ne 0 -or $res -ne 0){
                    throw "Drop database failed."
                }
            }
        
        } else {
             Write-Host ""
             Write-Host "Skip build. "$VSProjectName".dacpac exists." -foregroundcolor green
        }

        Write-Host "Publish $($Projectname).dacpac"
        $sourceFile =$Projectpath+"\"+$VSProjectName+"\bin\Release\"+$Projectname+".dacpac"
        Write-Host $sourceFile
        Write-Host $vsLocation
        $SqlPackagePath = $env:Path -split ';'|?{$_ -and ((Test-Path -Path (Join-Path -Path $_ -ChildPath SqlPackage.exe) -PathType leaf))}
        if($SqlPackagePath){
            $SqlPackagePath = Join-Path -Path $SqlPackagePath -ChildPath SqlPackage.exe
        }else {
            if($IsVS2019only){
                #For VS2019
                $SqlPackagePath = "$vsLocation\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\150\sqlpackage.exe"
            } else {
                #For VS2022
                $SqlPackagePath = "$vsLocation\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\sqlpackage.exe"
            }
        }
        Write-Host $SqlPackagePath
        Write-Host "/Action:Publish /SourceFile:$($sourceFile) /TargetServerName:$($TargetServerName) /TargetDatabaseName:$($TargetDBname) /p:BlockOnPossibleDataLoss=False /p:IgnorePermissions=True"
        if($VSProjectName -eq "ods"){
               & $SqlPackagePath /Action:Publish /SourceFile:$sourceFile /TargetServerName:$TargetServerName /TargetDatabaseName:$TargetDBname /TargetEncryptConnection:False /p:BlockOnPossibleDataLoss=False /p:IgnorePermissions=True 
        } else {
               & $SqlPackagePath /Action:Publish /SourceFile:$sourceFile /TargetServerName:$TargetServerName /TargetDatabaseName:$TargetDBname /TargetEncryptConnection:False /p:BlockOnPossibleDataLoss=False /p:IgnorePermissions=True /v:ods=$TargetODSDBname
        }
        IF ($LASTEXITCODE -ne 0){
            throw "Publish failed."
        }
    
        $ExitCode = 0
        Write-Host $VSProjectName
        if($VSProjectName -eq "dwh"){
            break
        } elseif($VSProjectName -eq "ods"){
            $VSProjectName = "landing"
        } elseif($VSProjectName -eq "landing"){
            $VSProjectName = "dwh"
        }
        Write-Host "Finish project "$VSProjectName
        #Write-Host -NoNewLine 'Press any key to continue...';
        #$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

    } until( 1 -eq 0 )
}
catch {
  
  Write-Host "An error occurred:" -fore red
  Write-Host $_ -fore red
  Write-Host "Stack:"
  Write-Host $_.ScriptStackTrace
  $ExitCode = -1
}
$Projectpath = $Projectpath +"\ScriptsFolder"
Set-Location -Path $Projectpath
exit $ExitCode

