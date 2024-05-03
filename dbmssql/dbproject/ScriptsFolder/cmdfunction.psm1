
function ApplySqlScriptFromFolder {

  param (
      $Folder,
      $FileFilter,
      $TargetServerName,
      $TargetDBname,
      $SqlPassword
  )
  try{
  
      Write-Host "Step folder: "$Folder 
      Write-Host "Filter: "$FileFilter

      $Files = Get-ChildItem $Folder -Attributes !Directory -Filter $FileFilter
      for ($i=0; $i -lt $Files.count; $i++){
        $SqlFile = $Folder+"\"+$Files[$i]
        $error.Clear()
        $LASTEXITCODE = 0
        Write-Host "Step"$i": "$SqlFile
        IF ($SqlPassword.Length -eq 0 ) {
            Invoke-Sqlcmd  -InputFile $SqlFile -ServerInstance $TargetServerName -database $TargetDBname -QueryTimeout 65535 -ErrorAction 'Stop'
        } else {
            Invoke-Sqlcmd  -InputFile $SqlFile -OutputSqlErrors $true -ServerInstance $TargetServerName -database $TargetDBname -QueryTimeout 65535 -ErrorAction 'Stop' -username 'admindb' -password $SqlPassword
        }

    }
      
  } catch { 
    Write-Host "Exec sqlcmd: An sql error occurred "$folder$action -fore red
    Write-Host $_ -fore red
    return -1
    
  }
  return 0
}
function Get-VsInstallation
{
  Param 
  (
    [bool] $allowPreviewVersions = $false
  )
  #-Descending
  $valuesToLookFor = @(
    'Visual Studio Community 2019',
    'Visual Studio Professional 2019')
    if ($allowPreviewVersions) {
       Write-Host "We are looking only among these versions: " 
       Write-Host $valuesToLookFor
#      $latestVsInstallationInfo = Get-VSSetupInstance -All -Prerelease | Sort-Object -Property InstallationVersion -Descending | Select-Object -First 1
       $latestVsInstallationInfo = Get-VSSetupInstance -All -Prerelease | Sort-Object -Property InstallationVersion -Descending | Where-Object -FilterScript {$valuesToLookFor -contains $_.DisplayName} | Select-Object -First 1

    } else {
      $latestVsInstallationInfo = Get-VSSetupInstance -All | Sort-Object -Property InstallationVersion -Descending | Select-Object -First 1
    }

    if($null -eq $latestVsInstallationInfo) {
        Write-Host "Visual Studio not found." -foregroundcolor red
    } else {
        Write-Host "Visual Studio was successfully found." -foregroundcolor green
        Write-Host "VS: $($latestVsInstallationInfo.DisplayName). Version installed is $($latestVsInstallationInfo.InstallationVersion)"
    }
   
    return $latestVsInstallationInfo
}

function Get-MsbuildLocation
{
  Param 
  (
    [bool] $allowPreviewVersions = $false
  )

    $latestVsInstallationInfo = Get-VsInstallation($allowPreviewVersions)
    if ($latestVsInstallationInfo.InstallationVersion -like "15.*") {
      $msbuildLocation = "$($latestVsInstallationInfo.InstallationPath)\MSBuild\15.0\Bin\msbuild.exe"
    
      Write-Host "Located msbuild for Visual Studio 2017 in $msbuildLocation"
    } else {
      $msbuildLocation = "$($latestVsInstallationInfo.InstallationPath)\MSBuild\Current\Bin\msbuild.exe"
      Write-Host "Located msbuild in $msbuildLocation"
    }

    return $msbuildLocation
}

function FixedParameter 
{

  param (
      $ExternalParameter
  )
  $LocalParameter 
  IF($ExternalParameter.Length -eq 0) {
    $LocalParameter = '""'
  }else{
      $LocalParameter = $ExternalParameter.Trim()
  }
  
  return $LocalParameter
}

    
function DropDatabaseFromServer 
{
  Param (
    [string]$lTargetDBname,
    [string]$lTargetServerName,
    [string]$lSQLuser,
    [string]$lSQLpwd
    )
    try{

      Write-Host  "Drop database: "$lTargetDBname" on server: $lTargetServerName"
      
      $lSqlCmd = "SET NOCOUNT ON; SELECT res=count(*) FROM sys.databases WHERE name='"+$lTargetDBname+"'"
      $lDataCount1 = sqlcmd -S $lTargetServerName  -d master  -Q $lSqlCmd -h -1
      $lDataCount = $lDataCount1.Trim()
      Write-Host "Record count: " $lDataCount
      if($lDataCount -ne 0) {
          Write-Host "Drop database  "$lTargetDBname
        $lSqlCmd = "
        DECLARE    @Spid INT
        DECLARE    @ExecSQL VARCHAR(255)
        
        DECLARE    KillCursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
        FOR
        SELECT    DISTINCT SPID
        FROM    MASTER..SysProcesses
        WHERE    DBID = DB_ID('"+$lTargetDBname+"')
        
        OPEN    KillCursor
        
        -- Grab the first SPID
        FETCH    NEXT
        FROM    KillCursor
        INTO    @Spid
        
        WHILE    @@FETCH_STATUS = 0
          BEGIN
            SET        @ExecSQL = 'KILL ' + CAST(@Spid AS VARCHAR(50))
        
            EXEC    (@ExecSQL)
        
            -- Pull the next SPID
                FETCH    NEXT 
            FROM    KillCursor 
            INTO    @Spid  
          END
        
        CLOSE    KillCursor
        
        DEALLOCATE    KillCursor
        GO
        ALTER DATABASE "+$lTargetDBname+"
          SET SINGLE_USER;
          GO
          DROP DATABASE "+$lTargetDBname
          $lDataCount1 = sqlcmd -S $lTargetServerName  -d master  -Q $lSqlCmd -h -1
      }

    return 0

    }
    catch {
        
      Write-Host "An error occurred:" -fore red
      Write-Host $_ -fore red
      return -1
    }    

}


function GetSqlValue {

  param (
      $TargetServerName,
      $TargetDBname,
      $SqlCmd,
      [ref]$res
  )
  try{
    $sqlConnectionString = "Data Source=" + $TargetServerName + ";Initial Catalog="+$TargetDBname+";Integrated Security=SSPI;"
    
    $sqlConnectionExec = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

    $sqlConnectionExec.Open()
    
    $SqlCmdObj = New-Object System.Data.SqlClient.SqlCommand ($SqlCmd, $sqlConnectionExec)

    $reader = $SqlCmdObj.ExecuteReader()
    
    #$tmp = $reader.Read()
    
    $res.Value = [int]($reader.GetValue(0))
    
    $reader.Dispose()

    $sqlConnectionExec.Dispose()
    
    return 0
    
  } catch { 
    Write-Host "Exec sqlcmd: An sql error occurred "$folder$action -fore red
    Write-Host $_ -fore red
    return -1
    
  }
  return 0
}

function RunSSISPackage {

  param (
      $PackageName,
      $TargetServerName,
      $TargetFolderName,
      $ProjectName
  )
  try{

    # Run SSIS
    $SSISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"

     

    # Load the IntegrationServices assembly
    Add-Type -AssemblyName "Microsoft.SQLServer.Management.IntegrationServices, Version=15.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91, processorArchitecture=MSIL"

    # Create a connection to the server
    $sqlConnectionString = "Data Source=" + $TargetServerName + ";Initial Catalog=master;Integrated Security=SSPI;"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

    # Create the Integration Services object
    $integrationServices = New-Object $SSISNamespace".IntegrationServices" $sqlConnection
    
    # Get the Integration Services catalog
    $catalog = $integrationServices.Catalogs["SSISDB"]

    # Get the folder
    $folder = $catalog.Folders[$TargetFolderName]

    # Get the project
    $project = $folder.Projects[$ProjectName]

    # Get the package
    $package = $project.Packages[$PackageName]
    Write-Host "Running " $PackageName "..."
    Write-Host ""
    $result = $package.Execute("false", $null)
        IF ($LASTEXITCODE -ne 0){
            Write-Host $result
            throw "SSIS Package filed."
        }
    
    return 0
    
  } catch { 
    Write-Host "Exec sqlcmd: An sql error occurred "$folder$action -fore red
    Write-Host $_ -fore red
    return -1
    
  }
  return 0
}
