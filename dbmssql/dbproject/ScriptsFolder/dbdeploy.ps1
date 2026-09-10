#Requires -Version 5.1
<#
.SYNOPSIS
    Build and publish SSDT projects: log -> Layers[] (DatabaseName folders).

.DESCRIPTION
    Generated from Layers metadata. ProjectFolder = Layer.DatabaseName (folder + .sqlproj name).
    ServerDatabase = {Client}_{DatabaseName}. Log is always first (not a Layer).

.PARAMETER Project
    Deploy subset: all | log | {ProjectFolder from Layers} (dependencies: log + prior layers in order).

.PARAMETER PublishOnly
    Do not drop databases before publish. Still rebuilds dacpac when -IsRebuild or dacpac is missing.

.PARAMETER IsRebuild
    Force MSBuild rebuild even if dacpac already exists.
#>
[CmdletBinding()]
param(
    [string]$TargetServerName = 'localhost',
    [string]$Project = 'all',
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [switch]$PublishOnly,
    [switch]$IsRebuild,
    [string]$SqlUser,
    [string]$SqlPassword
)

$ErrorActionPreference = 'Stop'

# --- generated from Layers (do not edit by hand; regenerate stand) ---
$LogServerDatabase = 'newadwh_log'
$FirstOdsServerDatabase = 'newadwh_ods'
$LandingServerDatabase = 'newadwh_landing'
$ClientName = 'newadwh'

$generatedLayers = @(
  [pscustomobject]@{
    Key            = 'ods'
    ProjectFolder  = 'ods'
    ServerDatabase = 'newadwh_ods'
    Role           = 'Ods'
    IsFirstOds     = [System.Convert]::ToBoolean('true')
    IsLandingLike  = [System.Convert]::ToBoolean('false')
    IsOds          = [System.Convert]::ToBoolean('true')
    IsDwh          = [System.Convert]::ToBoolean('false')
    IsDwhHistory   = [System.Convert]::ToBoolean('false')
  }
  [pscustomobject]@{
    Key            = 'landing'
    ProjectFolder  = 'landing'
    ServerDatabase = 'newadwh_landing'
    Role           = 'Ods'
    IsFirstOds     = [System.Convert]::ToBoolean('false')
    IsLandingLike  = [System.Convert]::ToBoolean('true')
    IsOds          = [System.Convert]::ToBoolean('true')
    IsDwh          = [System.Convert]::ToBoolean('false')
    IsDwhHistory   = [System.Convert]::ToBoolean('false')
  }
  [pscustomobject]@{
    Key            = 'dwh'
    ProjectFolder  = 'dwh'
    ServerDatabase = 'newadwh_dwh'
    Role           = 'Dwh'
    IsFirstOds     = [System.Convert]::ToBoolean('false')
    IsLandingLike  = [System.Convert]::ToBoolean('false')
    IsOds          = [System.Convert]::ToBoolean('false')
    IsDwh          = [System.Convert]::ToBoolean('true')
    IsDwhHistory   = [System.Convert]::ToBoolean('false')
  }
)

function Get-ClientNameFromScriptRoot {
    # .../<client>/dbmssql/dbproject/ScriptsFolder
    Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) -Leaf
}

function Get-DeployEntries {
    param([string]$SelectedProject)

    $logEntry = [pscustomobject]@{
        Key            = 'log'
        ProjectFolder  = 'log'
        ServerDatabase = $LogServerDatabase
        Role           = 'Log'
        IsFirstOds     = $false
        IsLandingLike  = $false
        IsOds          = $false
        IsDwh          = $false
        IsDwhHistory   = $false
    }

    $all = @($logEntry) + @($generatedLayers)
    if ($SelectedProject -eq 'all') {
        return $all
    }

    $match = $all | Where-Object { $_.Key -eq $SelectedProject -or $_.ProjectFolder -eq $SelectedProject }
    if (-not $match) {
        $keys = ($all | ForEach-Object { $_.Key }) -join ', '
        throw "Unknown -Project '$SelectedProject'. Expected: all, $keys"
    }

    $targetIndex = [array]::IndexOf($all, @($match)[0])
    if ($targetIndex -lt 0) {
        for ($i = 0; $i -lt $all.Count; $i++) {
            if ($all[$i].Key -eq $SelectedProject -or $all[$i].ProjectFolder -eq $SelectedProject) {
                $targetIndex = $i
                break
            }
        }
    }

    return $all[0..$targetIndex]
}

function Get-PublishSqlCmdArgs {
    param(
        [Parameter(Mandatory)]$Entry,
        [string]$LogDb,
        [string]$LandingDb,
        [string]$OdsDb
    )

    $selfDb = $Entry.ServerDatabase
    $auditBase = @(
        "/v:log=$LogDb",
        '/v:LinkSRVLog=LinkSRVLog',
        '/v:LinkSRVLogLanding=LinkSRVLogLanding',
        "/v:landing=$LandingDb"
    )

    if ($Entry.Role -eq 'Log') {
        return @("/v:log=$LogDb")
    }

    if ($Entry.IsOds) {
        # ODS / landing-like: audit loopback на эту же БД
        return $auditBase + "/v:ods=$selfDb"
    }

    if ($Entry.IsDwh -or $Entry.IsDwhHistory) {
        $odsArgs = @(
            "/v:ods=newadwh_ods",
            '/v:LinkSRVOds=LinkSRVOds',
            '/v:LinkSRVLanding=LinkSRVLanding'
        )
        return $auditBase + @(
            "/v:dwh=$selfDb"
        ) + $odsArgs
    }

    throw "Unknown layer role: $($Entry.Role) (folder $($Entry.ProjectFolder))"
}

function Resolve-SsdProject {
    param(
        [Parameter(Mandatory)]$Entry,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Configuration
    )

    $folder = $Entry.ProjectFolder
    $dir = Join-Path $ProjectRoot $folder
    if (-not (Test-Path -LiteralPath $dir)) {
        return $null
    }

    $preferred = Join-Path $dir "$folder.sqlproj"
    if (Test-Path -LiteralPath $preferred) {
        return [pscustomobject]@{
            Folder      = $dir
            FolderName  = $folder
            ProjectFile = $preferred
            ProjName    = $folder
            DacpacPath  = Join-Path $dir "bin\$Configuration\$folder.dacpac"
        }
    }

    foreach ($legacy in @('ods', 'landing', 'dwh', 'log')) {
        $proj = Join-Path $dir "$legacy.sqlproj"
        if (Test-Path -LiteralPath $proj) {
            return [pscustomobject]@{
                Folder      = $dir
                FolderName  = $folder
                ProjectFile = $proj
                ProjName    = $legacy
                DacpacPath  = Join-Path $dir "bin\$Configuration\$legacy.dacpac"
            }
        }
    }

    $any = Get-ChildItem -LiteralPath $dir -Filter '*.sqlproj' -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($any) {
        $projName = [IO.Path]::GetFileNameWithoutExtension($any.Name)
        return [pscustomobject]@{
            Folder      = $dir
            FolderName  = $folder
            ProjectFile = $any.FullName
            ProjName    = $projName
            DacpacPath  = Join-Path $dir "bin\$Configuration\$projName.dacpac"
        }
    }

    return $null
}

if (-not $ClientName) {
    $ClientName = Get-ClientNameFromScriptRoot
}

$Projectpath = Convert-Path (Join-Path $PSScriptRoot '..')
$ExitCode = 0
$deployEntries = @(Get-DeployEntries -SelectedProject $Project)

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

    Write-Host "Client:        $ClientName" -ForegroundColor DarkGray
    Write-Host "MSBuild:       $msbuildLocation" -ForegroundColor DarkGray
    Write-Host "SqlPackage:    $SqlPackagePath" -ForegroundColor DarkGray
    Write-Host "Configuration: $Configuration" -ForegroundColor DarkGray
    $orderKeys = ($deployEntries | ForEach-Object { $_.Key }) -join ' -> '
    Write-Host "Deploy order:  $orderKeys" -ForegroundColor DarkGray
    $dbList = ($deployEntries | ForEach-Object { "$($_.Key)=$($_.ServerDatabase)" }) -join ', '
    Write-Host "Databases:     $dbList" -ForegroundColor DarkGray
    Write-Host ''

    foreach ($entry in $deployEntries) {
        $targetDb = $entry.ServerDatabase
        $resolved = Resolve-SsdProject -Entry $entry -ProjectRoot $Projectpath -Configuration $Configuration

        if (-not $resolved) {
            Write-Warning "Skip layer $($entry.Key): no project under '$($entry.ProjectFolder)'."
            continue
        }

        $projectFile = $resolved.ProjectFile
        $dacpacPath = $resolved.DacpacPath

        Set-Location $resolved.Folder

        Write-Host '=========================================================' -ForegroundColor Green
        Write-Host "Layer:    $($entry.Key) ($($entry.Role))" -ForegroundColor Green
        Write-Host "Folder:   $($resolved.FolderName) /$($resolved.ProjName).sqlproj" -ForegroundColor Green
        Write-Host "Database: $targetDb" -ForegroundColor Green
        Write-Host "Server:   $TargetServerName" -ForegroundColor Green
        Write-Host '=========================================================' -ForegroundColor Green

        $needBuild = $IsRebuild -or -not (Test-Path -LiteralPath $dacpacPath)
        if ($needBuild) {
            Write-Host "BUILD $($entry.Key) ($Configuration)" -ForegroundColor Cyan
            & $msbuildLocation $projectFile `
                -t:Rebuild `
                -p:Configuration=$Configuration `
                -p:WarningLevel=0 `
                -p:NoWarn=SQL71562 `
                -v:minimal `
                -nologo
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed for [$($entry.Key)] (exit code $LASTEXITCODE)."
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

        if (-not (Test-Path -LiteralPath $dacpacPath)) {
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
        ) + (Get-PublishSqlCmdArgs -Entry $entry -LogDb $LogServerDatabase -LandingDb $LandingServerDatabase -OdsDb $FirstOdsServerDatabase)

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
            throw "Publish failed for [$($entry.Key)] / [$targetDb] (exit code $LASTEXITCODE). See SqlPackage output above."
        }

        Write-Host "[OK] $($entry.Key) -> [$targetDb]" -ForegroundColor Green
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
