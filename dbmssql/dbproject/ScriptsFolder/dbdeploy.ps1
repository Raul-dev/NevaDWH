#Requires -Version 5.1
<#
.SYNOPSIS
    Build and publish SSDT projects: log -> landing -> ods -> dwh.

.DESCRIPTION
    Runs MSBuild + SqlPackage for client dbproject layers.
    SqlCmd variables match linked-server audit routing (log / landing loopback / central log).

.PARAMETER Project
    Deploy subset: all, log, landing, ods, dwh (dependencies included in build/deploy order).

.PARAMETER PublishOnly
    Do not drop databases before publish. Still rebuilds dacpac when -IsRebuild or dacpac is missing.

.PARAMETER IsRebuild
    Force MSBuild rebuild even if dacpac already exists.

.EXAMPLE
    .\dbdeploy.ps1

.EXAMPLE
    .\dbdeploy.ps1 -Project dwh -PublishOnly -Configuration Debug

.EXAMPLE
    .\dbdeploy.ps1 -TargetLogDBname newadwh_log -TargetLandingDBname newadwh_landing `
        -TargetODSDBname newadwh_ods -TargetDWHDBname newadwh_dwh
#>
[CmdletBinding()]
param(
    [string]$TargetServerName = 'localhost',
    [string]$TargetLogDBname,
    [string]$TargetLandingDBname,
    [string]$TargetODSDBname,
    [string]$TargetDWHDBname,
    [ValidateSet('all', 'log', 'landing', 'ods', 'dwh')]
    [string]$Project = 'all',
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [switch]$PublishOnly,
    [switch]$IsRebuild,
    [string]$SqlUser,
    [string]$SqlPassword
)

$ErrorActionPreference = 'Stop'

function Get-ClientNameFromScriptRoot {
    # .../<client>/dbmssql/dbproject/ScriptsFolder
    Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) -Leaf
}

function Get-DeployProjectOrder {
    param([string]$SelectedProject)
    switch ($SelectedProject) {
        'log'     { @('log') }
        'landing' { @('log', 'landing') }
        'ods'     { @('log', 'landing', 'ods') }
        'dwh'     { @('log', 'landing', 'ods', 'dwh') }
        default   { @('log', 'landing', 'ods', 'dwh') }
    }
}

function Get-PublishSqlCmdArgs {
    param(
        [string]$Layer,
        [string]$LogDb,
        [string]$LandingDb,
        [string]$OdsDb,
        [string]$DwhDb
    )

    $auditBase = @(
        "/v:log=$LogDb",
        '/v:LinkSRVLog=LinkSRVLog',
        '/v:LinkSRVLogLanding=LinkSRVLogLanding',
        "/v:landing=$LandingDb"
    )

    switch ($Layer) {
        'log' {
            return @("/v:log=$LogDb")
        }
        'landing' {
            # landing audit procs call [LinkSRVLogLanding].[ods].audit.*
            return $auditBase + "/v:ods=$OdsDb"
        }
        'ods' {
            return $auditBase + "/v:ods=$OdsDb"
        }
        'dwh' {
            return $auditBase + @(
                "/v:ods=$OdsDb",
                "/v:dwh=$DwhDb",
                '/v:LinkSRVLanding=LinkSRVLanding',
                '/v:LinkSRVOds=LinkSRVOds'
            )
        }
        default {
            throw "Unknown layer: $Layer"
        }
    }
}

$clientName = Get-ClientNameFromScriptRoot
if (-not $TargetLogDBname)     { $TargetLogDBname = "${clientName}_log" }
if (-not $TargetLandingDBname) { $TargetLandingDBname = "${clientName}_landing" }
if (-not $TargetODSDBname)     { $TargetODSDBname = "${clientName}_ods" }
if (-not $TargetDWHDBname)     { $TargetDWHDBname = "${clientName}_dwh" }

$dbNames = @{
    log     = $TargetLogDBname
    landing = $TargetLandingDBname
    ods     = $TargetODSDBname
    dwh     = $TargetDWHDBname
}

$Projectpath = Convert-Path (Join-Path $PSScriptRoot '..')
$ExitCode = 0
$deployOrder = Get-DeployProjectOrder -SelectedProject $Project

Import-Module -Name (Join-Path $PSScriptRoot 'MSqlDeploymentFunc.psm1') -Force

try {
    $msbuildLocation = Get-MsBuildPath
    if (-not $msbuildLocation) {
        throw 'MSBuild not found. Install Visual Studio with workload "Data storage and processing" (SSDT).'
    }

    $vsLocation = Get-VisualStudioInstallPath
    $SqlPackagePath = Get-SqlPackagePath -VsInstallationPath $vsLocation
    if (-not $SqlPackagePath) {
        throw 'SqlPackage.exe not found.'
    }

    Write-Host "Client:        $clientName" -ForegroundColor DarkGray
    Write-Host "MSBuild:       $msbuildLocation" -ForegroundColor DarkGray
    Write-Host "SqlPackage:    $SqlPackagePath" -ForegroundColor DarkGray
    Write-Host "Configuration: $Configuration" -ForegroundColor DarkGray
    Write-Host "Deploy order:  $($deployOrder -join ' -> ')" -ForegroundColor DarkGray
    $dbList = ($deployOrder | ForEach-Object { "$_=$($dbNames[$_])" }) -join ', '
    Write-Host "Databases:     $dbList" -ForegroundColor DarkGray
    Write-Host ''

    foreach ($layer in $deployOrder) {
        $targetDb = $dbNames[$layer]
        $projectFile = Join-Path $Projectpath "$layer\$layer.sqlproj"
        $dacpacPath = Join-Path $Projectpath "$layer\bin\$Configuration\$layer.dacpac"

        if (-not (Test-Path $projectFile)) {
            throw "Project file not found: $projectFile"
        }

        Set-Location (Join-Path $Projectpath $layer)

        Write-Host '=========================================================' -ForegroundColor Green
        Write-Host "Layer:    $layer" -ForegroundColor Green
        Write-Host "Database: $targetDb" -ForegroundColor Green
        Write-Host "Server:   $TargetServerName" -ForegroundColor Green
        Write-Host '=========================================================' -ForegroundColor Green

        $needBuild = $IsRebuild -or -not (Test-Path $dacpacPath)
        if ($needBuild) {
            Write-Host "BUILD $layer ($Configuration)" -ForegroundColor Cyan
            & $msbuildLocation $projectFile `
                -t:Rebuild `
                -p:Configuration=$Configuration `
                -p:WarningLevel=0 `
                -p:NoWarn=SQL71562 `
                -v:minimal `
                -nologo
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed for [$layer] (exit code $LASTEXITCODE)."
            }
        } else {
            Write-Host "Skip build - dacpac exists: $dacpacPath" -ForegroundColor DarkGray
        }

        if (-not $PublishOnly) {
            $dropResult = DropDatabase -TargetDatabaseName $targetDb -TargetServerName $TargetServerName -SqlUser $SqlUser -SqlPassword $SqlPassword
            if ($dropResult -ne 0) {
                throw "Drop database failed for [$targetDb]."
            }
        }

        if (-not (Test-Path $dacpacPath)) {
            throw "Dacpac not found after build: $dacpacPath"
        }

        $publishArgs = @(
            '/Action:Publish'
            "/SourceFile:$dacpacPath"
            "/TargetServerName:$TargetServerName"
            "/TargetDatabaseName:$targetDb"
            '/TargetEncryptConnection:False'
            '/p:BlockOnPossibleDataLoss=False'
            '/p:IgnorePermissions=True'
        ) + (Get-PublishSqlCmdArgs -Layer $layer -LogDb $TargetLogDBname -LandingDb $TargetLandingDBname -OdsDb $TargetODSDBname -DwhDb $TargetDWHDBname)

        if ($SqlUser) {
            $publishArgs += "/TargetUser:$SqlUser"
            if ($SqlPassword) {
                $publishArgs += "/TargetPassword:$SqlPassword"
            }
        }

        Write-Host "PUBLISH -> [$targetDb]" -ForegroundColor Cyan
        Write-Host ($SqlPackagePath + ' ' + ($publishArgs -join ' ')) -ForegroundColor DarkGray
        & $SqlPackagePath @publishArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Publish failed for [$layer] / [$targetDb] (exit code $LASTEXITCODE). See SqlPackage output above."
        }

        Write-Host "[OK] $layer -> [$targetDb]" -ForegroundColor Green
        Write-Host ''
    }
}
catch {
    Write-Host 'Deploy failed:' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    $ExitCode = 1
}
finally {
    Set-Location $PSScriptRoot
}

exit $ExitCode
