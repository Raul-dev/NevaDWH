#Requires -Version 5.1
<#
.SYNOPSIS
  Engine-specific SQL/helpers for db-tests.ps1 (mssql, psql, ...).

.DESCRIPTION
  Dot-sourced by db-tests.ps1. To support another stand/engine:
    1) Add New-DbTestEngine<Name> below
    2) Register it in Get-DbTestEngine
  Each engine exposes the same keys used by the test harness.
#>

function Get-DbTestEngine {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('dbmssql', 'dbpsql')]
    [string]$Stand
  )
  switch ($Stand) {
    'dbmssql' { return (New-DbTestEngineMssql) }
    'dbpsql' { return (New-DbTestEnginePsql) }
    default { throw "Unsupported Stand='$Stand' - register engine in db-tests.engines.ps1" }
  }
}

function New-DbTestEngineMssql {
  return [ordered]@{
    Id    = 'mssql'
    Label = 'mssql'

    OdinsTables     = @('DIM_Валюты', 'DIM_Клиенты', 'DIM_Товары', 'FACT_Продажи', 'FACT_Продажи.Товары', 'DIM_Валюты.Представления')
    # MQ consumer writes *Buffer first (MSSQL naming); main odins.* may be emptied after Airflow ETL
    OdinsBufferTables = @('DIM_ВалютыBuffer', 'DIM_КлиентыBuffer', 'DIM_ТоварыBuffer', 'FACT_ПродажиBuffer')
    DwhEntityTables = @('DIM_Валюты', 'DIM_Клиенты', 'DIM_Товары', 'FACT_Продажи', 'FACT_Продажи.Товары', 'DIM_Валюты.Представления')
    # Parent → child: after ETL, parent rows must have tabular section rows too
    SalesParentTable = 'FACT_Продажи'
    SalesChildTable  = 'FACT_Продажи.Товары'
    GetSalesLinesQualitySql = {
      param([string]$Schema)
      @"
SELECT CAST(COUNT(*) AS varchar(20)) + '|' +
       CAST(SUM(CASE WHEN [Товар] IS NOT NULL THEN 1 ELSE 0 END) AS varchar(20)) + '|' +
       CAST(ISNULL(SUM([Колличество]), 0) AS varchar(40))
FROM [$Schema].[FACT_Продажи.Товары]
"@
    }.GetNewClosure()
    OdinsTruncateOrder = @(
      'DIM_Валюты.Представления',
      'FACT_Продажи.Товары',
      'DIM_Валюты',
      'DIM_Клиенты',
      'DIM_Товары',
      'FACT_Продажи'
    )

    FormatTableRef = {
      param([string]$Schema, [string]$Table)
      '[{0}].[{1}]' -f $Schema, $Table
    }.GetNewClosure()

    GetCountSql = {
      param([string]$Schema, [string]$Table)
      'SELECT COUNT(*) FROM [{0}].[{1}]' -f $Schema, $Table
    }.GetNewClosure()

    GetTimeMarkerSql = {
      'SELECT CONVERT(varchar(33), DATEADD(second, -2, SYSDATETIME()), 126)'
    }.GetNewClosure()

    GetOdinsFreshCountSql = {
      param([string]$Table, [string]$Marker)
      @(
        "SELECT COUNT(*) FROM [odins].[$Table]"
        "WHERE [CreatedAt] >= CONVERT(datetime2(4), '$Marker', 126)"
        "   OR [UpdatedAt] >= CONVERT(datetime2(4), '$Marker', 126)"
      ) -join "`n"
    }.GetNewClosure()

    GetTruncateOdinsSql = {
      param([string[]]$Tables)
      ($Tables | ForEach-Object { 'TRUNCATE TABLE [odins].[{0}]' -f $_ }) -join ";`n"
    }.GetNewClosure()

    GetMsgQueueCountSql = {
      'SELECT COUNT(*) FROM [mq].[MessageQueue]'
    }.GetNewClosure()

    MsgQueueEmptyHint = {
      'mq.MessageQueue is empty; redeploy ODS PostDeploy Dictionaries/messagequeue.sql'
    }.GetNewClosure()

    InvokeScalar = {
      param(
        [string]$Database,
        [string]$Sql,
        [string]$SqlUser,
        [string]$SqlPassword,
        [scriptblock]$GetTool,
        [string]$PostgresContainer = $null
      )
      $sqlcmd = & $GetTool @('sqlcmd')
      if (-not $sqlcmd) { throw 'sqlcmd not in PATH (required for dbmssql)' }
      $batch = "SET NOCOUNT ON; $Sql"
      $oldEap = $ErrorActionPreference
      $ErrorActionPreference = 'Continue'
      $out = & $sqlcmd -S 'localhost,1433' -U $SqlUser -P $SqlPassword -d $Database -h -1 -W -Q $batch 2>&1
      $code = $LASTEXITCODE
      $ErrorActionPreference = $oldEap
      if ($code -ne 0) {
        throw ("sqlcmd failed (exit {0}) db={1}: {2}" -f $code, $Database, (($out | Out-String).Trim()))
      }
      $text = (($out | Out-String) -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1)
      return ("$text").Trim()
    }.GetNewClosure()

    InvokeNonQuery = {
      param(
        [string]$Database,
        [string]$Sql,
        [string]$SqlUser,
        [string]$SqlPassword,
        [scriptblock]$GetTool,
        [string]$PostgresContainer = $null
      )
      $sqlcmd = & $GetTool @('sqlcmd')
      if (-not $sqlcmd) { throw 'sqlcmd not in PATH' }
      $oldEap = $ErrorActionPreference
      $ErrorActionPreference = 'Continue'
      $out = & $sqlcmd -S 'localhost,1433' -U $SqlUser -P $SqlPassword -d $Database -Q $Sql 2>&1
      $code = $LASTEXITCODE
      $ErrorActionPreference = $oldEap
      if ($code -ne 0) { throw ("sqlcmd failed: {0}" -f (($out | Out-String).Trim())) }
    }.GetNewClosure()
  }
}

function Invoke-DockerPsqlUtf8 {
  <#
    Feed SQL to psql as UTF-8 bytes on docker exec stdin.
    Do NOT pipe a PowerShell string into docker.exe: $OutputEncoding / OEM code page
    turns Cyrillic identifiers into "?" (e.g. DIM_??????).
  #>
  param(
    [Parameter(Mandatory)][string]$Docker,
    [Parameter(Mandatory)][string]$Container,
    [Parameter(Mandatory)][string]$Database,
    [Parameter(Mandatory)][string]$Sql,
    [string[]]$PsqlArgs = @()
  )
  $utf8 = New-Object System.Text.UTF8Encoding $false
  $argList = @('exec', '-i', $Container, 'psql', '-U', 'postgres', '-d', $Database, '-v', 'ON_ERROR_STOP=1') + $PsqlArgs
  # Quote args that need it for ProcessStartInfo.Arguments
  $argLine = ($argList | ForEach-Object {
      if ($_ -match '[\s"]') { '"{0}"' -f ($_ -replace '"', '\"') } else { $_ }
    }) -join ' '

  $p = New-Object System.Diagnostics.Process
  $psi = $p.StartInfo
  $psi.FileName = $Docker
  $psi.Arguments = $argLine
  $psi.UseShellExecute = $false
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $true
  [void]$p.Start()
  $bytes = $utf8.GetBytes($Sql)
  $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
  $p.StandardInput.BaseStream.Flush()
  $p.StandardInput.Close()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return [pscustomobject]@{
    ExitCode = $p.ExitCode
    Output   = (($stdout, $stderr) | Where-Object { $_ -and $_.Trim() -ne '' }) -join "`n"
  }
}

function New-DbTestEnginePsql {
  return [ordered]@{
    Id    = 'psql'
    Label = 'psql'
    PostgresContainer = 'client-postgresdb17'

    OdinsTables     = @('DIM_Валюты', 'DIM_Клиенты', 'DIM_Товары', 'FACT_Продажи', 'FACT_Продажи_Товары', 'DIM_Валюты_Представления')
    # MQ consumer writes *_buffer first; main odins.* may be emptied after Airflow ETL
    OdinsBufferTables = @('DIM_Валюты_buffer', 'DIM_Клиенты_buffer', 'DIM_Товары_buffer', 'FACT_Продажи_buffer')
    DwhEntityTables = @('DIM_Валюты', 'DIM_Клиенты', 'DIM_Товары', 'FACT_Продажи', 'FACT_Продажи_Товары', 'DIM_Валюты_Представления')
    # Parent → child: after ETL, parent rows must have tabular section rows too
    SalesParentTable = 'FACT_Продажи'
    SalesChildTable  = 'FACT_Продажи_Товары'
    GetSalesLinesQualitySql = {
      param([string]$Schema)
      @"
SELECT COUNT(*)::text || '|' ||
       COUNT("Товар")::text || '|' ||
       COALESCE(SUM("Колличество"),0)::text
FROM "$Schema"."FACT_Продажи_Товары"
"@
    }.GetNewClosure()
    # Postgres generator uses underscore instead of dot in child table names
    OdinsTruncateOrder = @(
      'DIM_Валюты_Представления',
      'FACT_Продажи_Товары',
      'DIM_Валюты',
      'DIM_Клиенты',
      'DIM_Товары',
      'FACT_Продажи'
    )

    FormatTableRef = {
      param([string]$Schema, [string]$Table)
      # Always quote - PG folds unquoted idents to lower-case
      '"{0}"."{1}"' -f $Schema, $Table
    }.GetNewClosure()

    GetCountSql = {
      param([string]$Schema, [string]$Table)
      'SELECT COUNT(*) FROM "{0}"."{1}"' -f $Schema, $Table
    }.GetNewClosure()

    GetTimeMarkerSql = {
      "SELECT to_char(now() - interval '2 seconds', 'YYYY-MM-DD HH24:MI:SS.MS')"
    }.GetNewClosure()

    GetOdinsFreshCountSql = {
      param([string]$Table, [string]$Marker)
      # ODS psql columns: created_at / updated_at (Snake; MSSQL uses CreatedAt/UpdatedAt)
      @(
        ('SELECT COUNT(*) FROM "odins"."{0}"' -f $Table)
        "WHERE created_at >= TIMESTAMP '$Marker'"
        "   OR updated_at >= TIMESTAMP '$Marker'"
      ) -join "`n"
    }.GetNewClosure()

    GetTruncateOdinsSql = {
      param([string[]]$Tables)
      ($Tables | ForEach-Object { 'TRUNCATE TABLE "odins"."{0}" CASCADE' -f $_ }) -join ";`n"
    }.GetNewClosure()

    GetMsgQueueCountSql = {
      'SELECT COUNT(*) FROM "mq"."msgqueue"'
    }.GetNewClosure()

    MsgQueueEmptyHint = {
      'mq.msgqueue is empty; seed via 070_msgqueue.sql (compose initdb) or pipe into: docker exec -i client-postgresdb17 psql -U postgres'
    }.GetNewClosure()

    # No GetNewClosure here: closed scriptblocks run in a private module and cannot see
    # session functions like Invoke-DockerPsqlUtf8.
    InvokeScalar = {
      param(
        [string]$Database,
        [string]$Sql,
        [string]$SqlUser,
        [string]$SqlPassword,
        [scriptblock]$GetTool,
        [string]$PostgresContainer = 'client-postgresdb17'
      )
      $docker = & $GetTool @('docker')
      if (-not $docker) { throw 'docker not in PATH' }
      $r = Invoke-DockerPsqlUtf8 -Docker $docker -Container $PostgresContainer -Database $Database -Sql $Sql -PsqlArgs @('-tA')
      if ($r.ExitCode -ne 0) {
        throw ("psql failed (exit {0}) db={1}: {2}" -f $r.ExitCode, $Database, ($r.Output.Trim()))
      }
      $text = ($r.Output -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1)
      return ("$text").Trim()
    }

    InvokeNonQuery = {
      param(
        [string]$Database,
        [string]$Sql,
        [string]$SqlUser,
        [string]$SqlPassword,
        [scriptblock]$GetTool,
        [string]$PostgresContainer = 'client-postgresdb17'
      )
      $docker = & $GetTool @('docker')
      if (-not $docker) { throw 'docker not in PATH' }
      $r = Invoke-DockerPsqlUtf8 -Docker $docker -Container $PostgresContainer -Database $Database -Sql $Sql
      if ($r.ExitCode -ne 0) {
        throw ("psql failed: {0}" -f ($r.Output.Trim()))
      }
    }
  }
}