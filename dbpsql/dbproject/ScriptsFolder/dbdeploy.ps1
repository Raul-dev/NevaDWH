# ./dbdeploy -TargetServerName localhost -TargetODSDBname "client3_ods" -TargetLandingDBname "client3_landing" -TargetDWHDBname "client3_dwh" -IsApplyScripts $false
Param (
	[parameter(Mandatory=$false)][string]$TargetServerName="localhost",
    [parameter(Mandatory=$false)][string]$TargetODSDBname="ods_uts_tmp", 
	[parameter(Mandatory=$false)][string]$TargetDWHDBname="dwh_uts_tmp", 
	[parameter(Mandatory=$false)][string]$TargetLandingDBname="landing_uts_tmp",
	[parameter(Mandatory=$false)][bool]$PublishOnly=$false,
	[parameter(Mandatory=$false)][string]$SqlPassword="postgres",
	[parameter(Mandatory=$false)][string]$IsApplyScripts=$true
  )
function ConcatenateScriptFolder
{
  Param 
  (
	[string] $SourceDBFolder,
	[string] $OutputDumpFile
  )
  
  Write-Host "Build DB dump script from folder: "$SourceDBFolder" to file "$OutputDumpFile
  $FileFilter = "*.sql"
  Write-Host "Source file filter: "$FileFilter
  Write-Host "Concatenate file folders: " + $SourceDBFolder
  Get-ChildItem $SourceDBFolder -Attributes !Directory
  $Files = Get-ChildItem $SourceDBFolder -Attributes !Directory -Filter $FileFilter
  for ($i=0; $i -lt $Files.count; $i++){
	  Write-Host $Files[$i].Name
	  $SqlFile = $SourceDBFolder+"\"+$Files[$i].Name
	  $error.Clear()
	  $LASTEXITCODE = 0
	  Write-Host "Step"$i": "$SqlFile
	  Get-Content -Encoding "UTF8" $SqlFile | Out-File -FilePath $OutputDumpFile -Encoding "UTF8" -Append
  
  }

}
function CreateDB ($DBServer, $DBPort, $Database, $Uid, $Pwd, $SqlScript) {
	#Create Database
	$DBConnectionString = "server=$DBServer;port=$DBPort;user id=$Uid;password=$Pwd;database=postgres;pooling=false"
	Write-Host $DBConnectionString
	$DBConn = New-Object Npgsql.NpgsqlConnection;
	$DBConn.ConnectionString = $DBConnectionString
	$DBConn.Open()
#	Register-ObjectEvent  -InputObject $DBConn -EventName Notice -Action {
#		Write-Host $(Get-Date) + "fff" + $event.SourceEventArgs.Notice.MessageText
#	}	
		
	$query = (" 
		do
		`$`$
		BEGIN
		RAISE NOTICE 'Drop connection from database $TargetODSDBname';
		END;
		`$`$;
		SELECT pid, pg_terminate_backend(pid) FROM pg_stat_get_activity(NULL::integer)
		WHERE datid = (SELECT oid FROM pg_database
				WHERE datname = '$TargetODSDBname');"
	)
	
	Write-Host $query
	$DBCmd = $DBConn.CreateCommand()
	$DBCmd.CommandText = $query
	$res = $DBCmd.ExecuteNonQuery();
	
	if($PublishOnly -eq $true){
		$query = (" 
		do
		`$`$
		BEGIN
		RAISE NOTICE 'Bul bul Create database $TargetODSDBname';
		if (NOT EXISTS(SELECT oid FROM pg_database WHERE datname = '$TargetODSDBname')) Then
			RAISE NOTICE 'Create database $TargetODSDBname';
			CREATE DATABASE $TargetODSDBname;
		END IF;
		END;
		`$`$;"
		)
	}else {
		$query = (" 
		DROP DATABASE IF EXISTS $TargetODSDBname;"
		)
		$DBCmd.CommandText = $query
		$res = $DBCmd.ExecuteNonQuery();
		$query = (" 
		CREATE DATABASE $TargetODSDBname;"
		)
	}
	Write-Host $query		
	$DBCmd.CommandText = $query
	$res = $DBCmd.ExecuteNonQuery();
	Write-Host $res
	$DBConn.Close()
	#Write-Host $SqlScript
	
	
}

function ExecutePsqlCmd ($DBServer, $DBPort, $Database, $Uid, $Pwd, $SqlScript) {

	$DBConnectionString = "server=$DBServer;port=$DBPort;user id=$Uid;password=$Pwd;database=$Database;pooling=false"
	Write-Host $DBConnectionString
	$DBConn = $null
	$DBConn = New-Object Npgsql.NpgsqlConnection;
	$DBConn.ConnectionString = $DBConnectionString
	$DBConn.Open()
	# Register event
	$null = Register-ObjectEvent  -InputObject $DBConn -EventName Notice -Action {
		Write-Host $(Get-Date) $event.SourceEventArgs.Notice.MessageText
	}	
	
	$DBCmd = $DBConn.CreateCommand()
	$DBCmd.CommandText = $SqlScript
	$res = $DBCmd.ExecuteNonQuery();
	$DBConn.Close();
	Get-EventSubscriber | Unregister-Event
}
try{

	#https://github.com/npgsql/npgsql/releases/download/v4.1.8/Npgsql.msi
	
	#Add-Type -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Npgsql\v4.0_4.1.8.0__5d8b90d52f46fda7\Npgsql.dll"
	#Add-Type -Path "Npgsql.dll"
	#Add-Type Npgsql: Unable to load one or more of the requested types.
	#[System.Reflection.Assembly]::LoadWithPartialName("Npgsql")
	#$bin = "C:\folder\with\DLLs"
	$bin="F:\Work\GitLab\gitlab.neva.loc\FirstTestGroup\generatordwh\src\services\PostgresNotify\ConsoleApp1\bin\Debug"
	Add-Type -Path "$bin\Npgsql.dll" -ReferencedAssemblies "$bin\System.*.dll"
	#Add-Type -Path "F:\Work\GitLab\gitlab.neva.loc\FirstTestGroup\generatordwh\src\services\PostgresNotify\ConsoleApp1\bin\Debug\Npgsql.dll" -ReferencedAssemblies "F:\Work\GitLab\gitlab.neva.loc\FirstTestGroup\generatordwh\src\services\PostgresNotify\ConsoleApp1\bin\Debug\System.*.dll"
	#Register-PackageSource -provider NuGet -name nugetRepository -location https://www.nuget.org/api/v2
	#Cant Install-Package Npgsql
	#Install-Package -force -verbose Npgsql
	#$pkg = find-package -name Microsoft.Data.Sqlite
	#$pkg = find-package -name Npgsql -RequiredVersion 4.1.8
	#install-package -force -scope currentUser -verbose $pkg
	
	#Npgsql.dll Unable to load one or more of the requested types.

	#find-package -name Npgsql -RequiredVersion 4.1.12
	#exit
	$ExitCode = 0
	#Install-Module PostgreSQLCmdlets
	#Create dump script
	$DBName = "ods"
	$SourceFolder = Convert-Path ..
	$OutputDumpFile = Convert-Path . 
	$OutputDumpFile = $OutputDumpFile + "\create_${DBName}.sql"
	$OutputdictionaryFile = Convert-Path . 
    $OutputdictionaryFile = $OutputdictionaryFile + "\dictionaries_${DBName}.sql"

	Remove-Item -Path $OutputdictionaryFile -Force -ErrorAction SilentlyContinue

	$SourceDBFolder = $SourceFolder + "\${DBName}\Security"
	Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue

	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile

	$SourceDBFolder = $SourceFolder + "\${DBName}\dbo\Tables"
	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile
	$SourceDBFolder = $SourceFolder + "\${DBName}\dbo\Stored Procedures"
	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile
	$SourceDBFolder = $SourceFolder + "\${DBName}"
	#$SchemaFolders = Get-ChildItem ..\${DBName} -Attributes Directory | Where-Object -FilterScript {($_.Name -ne 'dbo') -and ($_.Name -ne 'Dictionaries') -and ($_.Name -ne 'Security')}

	$SchemaFolders = Get-ChildItem $SourceDBFolder -Attributes Directory | Where-Object -FilterScript {($_.Name -ne 'dbo') -and ($_.Name -ne 'Dictionaries') -and ($_.Name -ne 'Security')}
	Write-Host $SchemaFolders
	for ($i=0; $i -lt $SchemaFolders.count; $i++){
		
		$SqlSchemaFolder = $SourceDBFolder+"\"+$SchemaFolders[$i].Name+"\Tables"
		Write-Host $SqlSchemaFolder
		ConcatenateScriptFolder $SqlSchemaFolder $OutputDumpFile
		$SqlSchemaFolder = $SourceDBFolder+"\"+$SchemaFolders[$i].Name+"\Stored Procedures"
		Write-Host $SqlSchemaFolder
		if (Test-Path $SqlSchemaFolder) {
			ConcatenateScriptFolder $SqlSchemaFolder $OutputDumpFile
		}
	}
	#Dictionaries
	$SourceDBFolder = $SourceFolder + "\${DBName}\Dictionaries"
	ConcatenateScriptFolder $SourceDBFolder $OutputdictionaryFile
	#dwh
	$DBName = "dwh"
	$SourceFolder = Convert-Path ..
	$OutputDumpFile = Convert-Path . 
	$OutputDumpFile = $OutputDumpFile + "\create_${DBName}.sql"
	$OutputdictionaryFile = Convert-Path . 
    $OutputdictionaryFile = $OutputdictionaryFile + "\dictionaries_${DBName}.sql"

	Remove-Item -Path $OutputdictionaryFile -Force -ErrorAction SilentlyContinue

	$SourceDBFolder = $SourceFolder + "\${DBName}\Security"
	Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue

	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile

	$SourceDBFolder = $SourceFolder + "\${DBName}\dbo\Tables"
	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile
	$SourceDBFolder = $SourceFolder + "\${DBName}\dbo\Stored Procedures"
	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile
	$SourceDBFolder = $SourceFolder + "\${DBName}"
	#$SchemaFolders = Get-ChildItem ..\${DBName} -Attributes Directory | Where-Object -FilterScript {($_.Name -ne 'dbo') -and ($_.Name -ne 'Dictionaries') -and ($_.Name -ne 'Security')}

	$SchemaFolders = Get-ChildItem $SourceDBFolder -Attributes Directory | Where-Object -FilterScript {($_.Name -ne 'dbo') -and ($_.Name -ne 'Dictionaries') -and ($_.Name -ne 'Security')}
	Write-Host $SchemaFolders
	for ($i=0; $i -lt $SchemaFolders.count; $i++){
		
		$SqlSchemaFolder = $SourceDBFolder+"\"+$SchemaFolders[$i].Name+"\Tables"
		Write-Host $SqlSchemaFolder
		ConcatenateScriptFolder $SqlSchemaFolder $OutputDumpFile
		$SqlSchemaFolder = $SourceDBFolder+"\"+$SchemaFolders[$i].Name+"\Stored Procedures"
		Write-Host $SqlSchemaFolder
		if (Test-Path $SqlSchemaFolder) {
			ConcatenateScriptFolder $SqlSchemaFolder $OutputDumpFile
		}
	}
	#Dictionaries
	$SourceDBFolder = $SourceFolder + "\${DBName}\Dictionaries"
	ConcatenateScriptFolder $SourceDBFolder $OutputdictionaryFile

	#Landing
	$DBName = "landing"
	$SourceFolder = Convert-Path ..
	$OutputDumpFile = Convert-Path . 
	$OutputDumpFile = $OutputDumpFile + "\create_${DBName}.sql"
	$OutputdictionaryFile = Convert-Path . 
    $OutputdictionaryFile = $OutputdictionaryFile + "\dictionaries_${DBName}.sql"

	Remove-Item -Path $OutputdictionaryFile -Force -ErrorAction SilentlyContinue

	$SourceDBFolder = $SourceFolder + "\${DBName}\Security"
	Remove-Item -Path $OutputDumpFile -Force -ErrorAction SilentlyContinue

	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile

	$SourceDBFolder = $SourceFolder + "\${DBName}\dbo\Tables"
	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile
	$SourceDBFolder = $SourceFolder + "\${DBName}\dbo\Stored Procedures"
	ConcatenateScriptFolder $SourceDBFolder $OutputDumpFile
	$SourceDBFolder = $SourceFolder + "\${DBName}"
	#$SchemaFolders = Get-ChildItem ..\${DBName} -Attributes Directory | Where-Object -FilterScript {($_.Name -ne 'dbo') -and ($_.Name -ne 'Dictionaries') -and ($_.Name -ne 'Security')}

	$SchemaFolders = Get-ChildItem $SourceDBFolder -Attributes Directory | Where-Object -FilterScript {($_.Name -ne 'dbo') -and ($_.Name -ne 'Dictionaries') -and ($_.Name -ne 'Security')}
	Write-Host $SchemaFolders
	for ($i=0; $i -lt $SchemaFolders.count; $i++){
		
		$SqlSchemaFolder = $SourceDBFolder+"\"+$SchemaFolders[$i].Name+"\Tables"
		Write-Host $SqlSchemaFolder
		ConcatenateScriptFolder $SqlSchemaFolder $OutputDumpFile
		$SqlSchemaFolder = $SourceDBFolder+"\"+$SchemaFolders[$i].Name+"\Stored Procedures"
		Write-Host $SqlSchemaFolder
		if (Test-Path $SqlSchemaFolder) {
			ConcatenateScriptFolder $SqlSchemaFolder $OutputDumpFile
		}
	}
	#Dictionaries
	$SourceDBFolder = $SourceFolder + "\${DBName}\Dictionaries"
	ConcatenateScriptFolder $SourceDBFolder $OutputdictionaryFile	
	
	if($IsApplyScripts -eq $false){
		exit 0
	}
	$SqlUser ="postgres"
	$Port=54321
	CreateDB $TargetServerName $Port $TargetODSDBname "postgres" "postgres" 
	Write-Host "Use script"
	Write-Host $OutputDumpFile
	$SqlScript = Get-Content -Delimiter "\n" -Encoding "UTF8" $OutputDumpFile 
	#	$SqlScript = Get-Content -Encoding "UTF8"  "E:\\Work\\GitLab\\gitlab.neva.loc\\generatordwh\\src\\dwhclients\\client1\\dbpsql\\ScriptsFolder\\create_objects.sql"	
	
	ExecutePsqlCmd $TargetServerName $Port $TargetODSDBname "postgres" "postgres" $SqlScript
	
	Write-Host "Apply dictionaries"
	$SqlScript = Get-Content -Delimiter "\n" -Encoding "UTF8" $OutputdictionaryFile
	ExecutePsqlCmd $TargetServerName $Port $TargetODSDBname "postgres" "postgres" $SqlScript
	exit 0

}
catch {
  
  Write-Host "An error occurred:" -fore red
  Write-Host $_ -fore red
  Write-Host "Stack:"
  Write-Host $_.ScriptStackTrace
  $ExitCode = -1
}
#$Projectpath = $Projectpath +"\ScriptsFolder"
#Set-Location -Path $Projectpath
exit $ExitCode

