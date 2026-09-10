#Requires -Version 5.1
<#
.SYNOPSIS
  Pipeline tests for src/dbprojects stands (dbmssql / dbpsql).

.DESCRIPTION
  Brings up the stand docker-compose (same idea as run-tests.ps1 stand rebuild),
  then runs selected test groups.

  -General (default if no group switch):
    Phase 1) POST send-unresolved-msg → Rabbit → MQ → odins *_buffer / entity tables
             (main odins.* may be emptied later by Airflow — that is OK)
    Phase 2) Airflow dwh_etl_start → DWH staging
    Phase 3) DWH target tables

  Default Stand is dbpsql (Postgres). For MSSQL use: .\db-tests.ps1 dbmssql
  -SkipCompose requires that stand's compose project already up (mq.webservice).

  Engine-specific SQL lives in db-tests.engines.ps1 (mssql / psql; extend there for new DBs).

.EXAMPLE
  .\db-tests.ps1
  .\db-tests.ps1 dbmssql
  .\db-tests.ps1 dbmssql -SkipCompose
  .\db-tests.ps1 -SkipCompose -ClearData
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('dbmssql', 'dbpsql')]
  [string]$Stand ,

  [switch]$All,
  [switch]$General,

  [switch]$SkipCompose,
  [switch]$Build,
  # When set: truncate odins entity tables before Phase 1. Default: keep data, detect fresh rows by engine timestamp cols.
  [switch]$ClearData,

  [string]$MqBaseUrl = 'http://127.0.0.1:8090',
  [string]$AirflowUrl = 'http://127.0.0.1:8080',
  # Airflow 3 SimpleAuth + RabbitMQ: admin/admin
  [string]$AirflowUser = 'admin',
  [string]$AirflowPassword = 'admin',

  [int]$ReadyTimeoutSec = 300,
  [int]$OdinsTimeoutSec = 180,
  [int]$EtlTimeoutSec = 1200,
  [int]$PollSec = 3
)

if ([string]::IsNullOrWhiteSpace($Stand)) {
  $Stand = Read-Host 'Stand (dbmssql / dbpsql)'
  $Stand = "$Stand".Trim()
  if ($Stand -notin @('dbmssql', 'dbpsql')) {
    throw "Invalid Stand='$Stand'. Use dbmssql or dbpsql."
  }
}

$ErrorActionPreference = 'Stop'
# UTF-8 without BOM — native pipes still unsafe for Cyrillic (see Invoke-DockerPsqlUtf8)
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding $false
[Console]::OutputEncoding = $script:Utf8NoBom
$OutputEncoding = $script:Utf8NoBom

$Root = $PSScriptRoot
$EnginesPath = Join-Path $Root 'db-tests.engines.ps1'
if (-not (Test-Path -LiteralPath $EnginesPath)) {
  throw "Engine module not found: $EnginesPath"
}
. $EnginesPath
$Engine = Get-DbTestEngine -Stand $Stand

$StandDir = Join-Path (Join-Path (Join-Path $Root 'src') 'dbprojects') $Stand
$ComposeFile = Join-Path $StandDir 'docker-compose.yml'
$EnvFile = Join-Path $StandDir '.env'

if (-not (Test-Path $ComposeFile)) {
  throw "Compose not found: $ComposeFile"
}
if (-not (Test-Path $EnvFile)) {
  throw ".env not found: $EnvFile (generate via start.ps1 / template)"
}

$runGeneral = [bool]$General -or (-not $All -and -not $General)
if ($All) {
  $runGeneral = $true
}

$Stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$ReportRoot = Join-Path $Root 'TestReport'
$RunDir = Join-Path $ReportRoot ("db-{0}-{1}" -f $Stand, $Stamp)
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

$Results = New-Object System.Collections.Generic.List[object]

$OdinsTables = @($Engine.OdinsTables)
$OdinsBufferTables = @($Engine.OdinsBufferTables)
$DwhEntityTables = @($Engine.DwhEntityTables)

function Get-Tool {
  param([string[]]$Names)
  foreach ($n in $Names) {
    $cmd = Get-Command $n -ErrorAction SilentlyContinue
    if ($cmd) {
      if ($cmd.Source) { return $cmd.Source }
      return $n
    }
  }
  return $null
}

function Add-Result {
  param(
    [string]$Name,
    [ValidateSet('PASS', 'FAIL', 'SKIP')]$Status,
    [string]$Detail = '',
    [string]$Log = '',
    [int]$Ms = 0
  )
  $Results.Add([pscustomobject]@{
      Name   = $Name
      Status = $Status
      Detail = $Detail
      Log    = $Log
      Ms     = $Ms
    }) | Out-Null
  $color = 'Gray'
  if ($Status -eq 'PASS') { $color = 'Green' }
  elseif ($Status -eq 'FAIL') { $color = 'Red' }
  elseif ($Status -eq 'SKIP') { $color = 'Yellow' }
  Write-Host ("[{0}] {1}  {2}" -f $Status, $Name, $Detail) -ForegroundColor $color
}

function Invoke-Logged {
  param(
    [string]$Name,
    [string]$File,
    [string[]]$Arguments,
    [string]$WorkDir,
    [string]$LogName
  )
  $logPath = Join-Path $RunDir $LogName
  Write-Host ""
  Write-Host ("=== {0} ===" -f $Name) -ForegroundColor Cyan
  $sw = [Diagnostics.Stopwatch]::StartNew()
  $exit = 0
  $prev = Get-Location
  try {
    Set-Location $WorkDir
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & $File @Arguments 2>&1
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $oldEap
    $lines = foreach ($item in $raw) {
      if ($item -is [System.Management.Automation.ErrorRecord]) {
        if ($null -ne $item.TargetObject -and "$($item.TargetObject)".Length -gt 0) {
          "$($item.TargetObject)"
        } else {
          $item.ToString()
        }
      } else {
        "$item"
      }
    }
    $lines | Out-File -FilePath $logPath -Encoding UTF8
  } catch {
    $exit = 1
    $_ | Out-String | Out-File -FilePath $logPath -Encoding UTF8 -Append
  } finally {
    Set-Location $prev
    $sw.Stop()
  }
  if ($null -eq $exit) { $exit = 0 }
  $rel = Join-Path ("db-{0}-{1}" -f $Stand, $Stamp) $LogName
  if ($exit -eq 0) {
    Add-Result -Name $Name -Status PASS -Detail ("exit 0, {0} ms" -f $sw.ElapsedMilliseconds) -Log $rel -Ms $sw.ElapsedMilliseconds
  } else {
    Add-Result -Name $Name -Status FAIL -Detail ("exit {0}, {1} ms" -f $exit, $sw.ElapsedMilliseconds) -Log $rel -Ms $sw.ElapsedMilliseconds
  }
  return ($exit -eq 0)
}

function Get-DotEnv {
  param([string]$Path)
  $map = @{}
  Get-Content -LiteralPath $Path -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#')) { return }
    $i = $line.IndexOf('=')
    if ($i -lt 1) { return }
    $k = $line.Substring(0, $i).Trim()
    $v = $line.Substring($i + 1).Trim()
    if (($v.StartsWith("'") -and $v.EndsWith("'")) -or ($v.StartsWith('"') -and $v.EndsWith('"'))) {
      $v = $v.Substring(1, $v.Length - 2)
    }
    $map[$k] = $v
  }
  return $map
}

$EnvMap = Get-DotEnv -Path $EnvFile
$OdsDb = if ($EnvMap['MQ_DATABASE']) { $EnvMap['MQ_DATABASE'] } else { throw 'MQ_DATABASE missing in .env' }
$DwhDb = if ($OdsDb -match '_ods$') { $OdsDb -replace '_ods$', '_dwh' } else { $OdsDb + '_dwh' }
$SqlUser = if ($EnvMap['MQ_USER']) { $EnvMap['MQ_USER'] } else { 'postgres' }
$SqlPassword = if ($EnvMap['MQ_PASSWORD']) { $EnvMap['MQ_PASSWORD'] } else { 'postgres' }

function Invoke-EngineSql {
  param(
    [ValidateSet('scalar', 'nonquery')]$Mode,
    [ValidateSet('ods', 'dwh')]$DatabaseKind,
    [string]$Sql
  )
  $db = if ($DatabaseKind -eq 'ods') { $OdsDb } else { $DwhDb }
  $invoke = if ($Mode -eq 'scalar') { $Engine.InvokeScalar } else { $Engine.InvokeNonQuery }
  $params = @{
    Database         = $db
    Sql              = $Sql
    SqlUser          = $SqlUser
    SqlPassword      = $SqlPassword
    GetTool          = ${function:Get-Tool}
  }
  if ($Engine['PostgresContainer']) {
    $params['PostgresContainer'] = $Engine.PostgresContainer
  }
  return & $invoke @params
}

function Invoke-SqlScalar {
  param(
    [ValidateSet('ods', 'dwh')]$DatabaseKind,
    [string]$Sql
  )
  return Invoke-EngineSql -Mode scalar -DatabaseKind $DatabaseKind -Sql $Sql
}

function Invoke-SqlNonQuery {
  param(
    [ValidateSet('ods', 'dwh')]$DatabaseKind,
    [string]$Sql
  )
  [void](Invoke-EngineSql -Mode nonquery -DatabaseKind $DatabaseKind -Sql $Sql)
}

function Get-TableCounts {
  param(
    [ValidateSet('ods', 'dwh')]$DatabaseKind,
    [string]$Schema,
    [string[]]$Tables
  )
  $counts = [ordered]@{}
  foreach ($t in $Tables) {
    $sql = & $Engine.GetCountSql $Schema $t
    $raw = Invoke-SqlScalar -DatabaseKind $DatabaseKind -Sql $sql
    $n = 0
    [void][int]::TryParse($raw, [ref]$n)
    $counts[$t] = $n
  }
  return $counts
}

function Get-DbTimeMarker {
  return Invoke-SqlScalar -DatabaseKind ods -Sql (& $Engine.GetTimeMarkerSql)
}

function Get-OdinsFreshCounts {
  param([string]$Marker)
  $counts = [ordered]@{}
  foreach ($t in $OdinsTables) {
    $sql = & $Engine.GetOdinsFreshCountSql $t $Marker
    $raw = Invoke-SqlScalar -DatabaseKind ods -Sql $sql
    $n = 0
    [void][int]::TryParse($raw, [ref]$n)
    $counts[$t] = $n
  }
  return $counts
}

function Get-CountSum {
  param($Counts)
  $sum = 0
  if ($null -eq $Counts) { return 0 }
  foreach ($k in $Counts.Keys) { $sum += [int]$Counts[$k] }
  return $sum
}

function Get-PositiveTableCount {
  param($Counts)
  $n = 0
  if ($null -eq $Counts) { return 0 }
  foreach ($k in $Counts.Keys) { if ([int]$Counts[$k] -gt 0) { $n++ } }
  return $n
}

function Clear-OdinsTargetTables {
  Write-Host 'ClearData: truncating odins entity tables...' -ForegroundColor Yellow
  $sql = & $Engine.GetTruncateOdinsSql -Tables @($Engine.OdinsTruncateOrder)
  Invoke-SqlNonQuery -DatabaseKind ods -Sql $sql
}

function Get-MsgQueueCount {
  $raw = Invoke-SqlScalar -DatabaseKind ods -Sql (& $Engine.GetMsgQueueCountSql)
  $n = 0
  [void][int]::TryParse($raw, [ref]$n)
  return $n
}

function Format-Counts {
  param($Counts)
  ($Counts.GetEnumerator() | ForEach-Object { '{0}={1}' -f $_.Key, $_.Value }) -join ', '
}

function Test-HttpOk {
  param(
    [string]$Url,
    [string]$Method = 'GET',
    [int]$TimeoutMs = 8000,
    [hashtable]$Headers = $null,
    # object (not [string]) so omitted arg stays $null — [string]$null becomes "" in PS
    $Body = $null,
    [string]$ContentType = 'application/json'
  )
  $result = [ordered]@{ Ok = $false; Code = 0; Body = ''; Detail = '' }
  try {
    $req = [System.Net.HttpWebRequest]::Create($Url)
    $req.Method = $Method
    $req.Timeout = $TimeoutMs
    $req.AllowAutoRedirect = $true
    $req.UserAgent = 'publicdwh-db-tests'
    $req.KeepAlive = $false
    if ($Headers) {
      foreach ($k in $Headers.Keys) {
        if ($k -eq 'Authorization') { $req.Headers['Authorization'] = $Headers[$k] }
        else { $req.Headers[$k] = $Headers[$k] }
      }
    }
    $methodUpper = "$Method".ToUpperInvariant()
    $writeBody = ($null -ne $Body) -and ($methodUpper -in @('POST', 'PUT', 'PATCH'))
    if ($writeBody) {
      $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$Body)
      $req.ContentType = $ContentType
      $req.ContentLength = $bytes.Length
      $stream = $req.GetRequestStream()
      $stream.Write($bytes, 0, $bytes.Length)
      $stream.Close()
    } elseif ($methodUpper -eq 'POST') {
      # POST without body (e.g. /service/start)
      $req.ContentLength = 0
    }
    $resp = $req.GetResponse()
    try {
      $code = [int]$resp.StatusCode
      $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
      $bodyText = $reader.ReadToEnd()
      $reader.Close()
      $result.Code = $code
      $result.Body = $bodyText
      $result.Ok = ($code -ge 200 -and $code -lt 300)
      $result.Detail = "HTTP $code"
    } finally {
      $resp.Close()
    }
  } catch [System.Net.WebException] {
    $ex = $_.Exception
    if ($ex.Response) {
      $httpResp = $ex.Response
      $code = [int]$httpResp.StatusCode
      $result.Code = $code
      try {
        $reader = New-Object System.IO.StreamReader($httpResp.GetResponseStream())
        $result.Body = $reader.ReadToEnd()
        $reader.Close()
      } catch { }
      $httpResp.Close()
      $result.Detail = "HTTP $code"
    } else {
      $result.Detail = $ex.Message
    }
  } catch {
    $result.Detail = $_.Exception.Message
  }
  return [pscustomobject]$result
}

function Test-TcpPortOpen {
  param([string]$HostName, [int]$Port, [int]$TimeoutMs = 1000)
  $client = $null
  try {
    $client = New-Object System.Net.Sockets.TcpClient
    $iar = $client.BeginConnect($HostName, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
    $client.EndConnect($iar)
    return $true
  } catch {
    return $false
  } finally {
    if ($client) { $client.Close() }
  }
}

function Wait-HttpOk {
  param(
    [string]$Url,
    [int]$TimeoutSec = 180,
    [string]$Name = 'http'
  )
  $uri = [Uri]$Url
  $hostName = $uri.Host
  # Prefer IPv4 loopback: Docker Desktop often publishes 0.0.0.0 only; localhost → ::1 hangs.
  if ($hostName -eq 'localhost') {
    $hostName = '127.0.0.1'
    $builder = New-Object System.UriBuilder($uri)
    $builder.Host = '127.0.0.1'
    $Url = $builder.Uri.AbsoluteUri
  }
  $port = $uri.Port
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  $lastDetail = ''
  $attempt = 0
  while ((Get-Date) -lt $deadline) {
    $attempt++
    if (-not (Test-TcpPortOpen -HostName $hostName -Port $port -TimeoutMs 1000)) {
      $lastDetail = ("tcp {0}:{1} closed" -f $hostName, $port)
      if ($attempt -eq 1 -or ($attempt % 6) -eq 0) {
        Write-Host ("  waiting {0}: {1}" -f $Name, $lastDetail) -ForegroundColor DarkGray
      }
      Start-Sleep -Seconds 2
      continue
    }
    $r = Test-HttpOk -Url $Url -TimeoutMs 5000
    if ($r.Ok) {
      if ($attempt -gt 1) {
        Write-Host ("  {0} ready after {1} attempt(s)" -f $Name, $attempt) -ForegroundColor DarkGray
      }
      return $true
    }
    $lastDetail = $r.Detail
    if ($attempt -eq 1 -or ($attempt % 6) -eq 0) {
      Write-Host ("  waiting {0}: {1} ({2})" -f $Name, $Url, $lastDetail) -ForegroundColor DarkGray
    }
    Start-Sleep -Seconds 3
  }
  Write-Host ("  {0} give up: {1}" -f $Name, $lastDetail) -ForegroundColor Yellow
  return $false
}

function Get-AirflowToken {
  $url = ($AirflowUrl.TrimEnd('/') + '/auth/token')
  $body = (@{ username = $AirflowUser; password = $AirflowPassword } | ConvertTo-Json -Compress)
  $r = Test-HttpOk -Url $url -Method 'POST' -Body $body -TimeoutMs 15000
  if (-not $r.Ok) {
    throw ("Airflow token failed: {0} body={1}" -f $r.Detail, $r.Body)
  }
  $json = $r.Body | ConvertFrom-Json
  if (-not $json.access_token) {
    throw ("Airflow token response has no access_token: {0}" -f $r.Body)
  }
  return [string]$json.access_token
}

function Invoke-AirflowApi {
  param(
    [string]$Method,
    [string]$Path,
    [string]$Token,
    [string]$Body = $null
  )
  $url = ($AirflowUrl.TrimEnd('/') + $Path)
  $headers = @{ Authorization = ('Bearer {0}' -f $Token) }
  return Test-HttpOk -Url $url -Method $Method -Headers $headers -Body $Body -TimeoutMs 30000
}

function Get-ComposeContainerId {
  param(
    [string]$Docker,
    [string]$Service
  )
  $oldEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $prev = Get-Location
  try {
    Set-Location $StandDir
    $id = (& $Docker compose -p $Stand -f $ComposeFile ps -q $Service 2>$null | Select-Object -First 1)
  } finally {
    Set-Location $prev
    $ErrorActionPreference = $oldEap
  }
  return ("$id").Trim()
}

function Get-DockerContainerHealth {
  param(
    [string]$Docker,
    [string]$ContainerId
  )
  if ([string]::IsNullOrWhiteSpace($ContainerId)) {
    return [pscustomobject]@{ Status = 'missing'; Health = ''; Running = $false }
  }
  $oldEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $health = (& $Docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' $ContainerId 2>$null)
  $running = (& $Docker inspect -f '{{.State.Running}}' $ContainerId 2>$null)
  $state = (& $Docker inspect -f '{{.State.Status}}' $ContainerId 2>$null)
  $ErrorActionPreference = $oldEap
  $health = ("$health").Trim()
  $state = ("$state").Trim()
  $isRunning = ("$running".Trim() -eq 'true')
  # Prefer Health when HEALTHCHECK exists; otherwise treat running as ready.
  $status = if ($health) { $health } elseif ($isRunning) { 'running' } else { $state }
  return [pscustomobject]@{
    Status  = $status
    Health  = $health
    Running = $isRunning
  }
}

function Wait-DockerHealthy {
  param(
    [string]$Docker,
    [string]$Service,
    [string]$Name,
    [int]$TimeoutSec = 300,
    [switch]$RequireHealthcheck,
    # When image has no HEALTHCHECK (health empty), probe this URL and accept 2xx.
    [string]$HttpFallbackUrl = ''
  )
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  $attempt = 0
  $last = ''
  while ((Get-Date) -lt $deadline) {
    $attempt++
    $id = Get-ComposeContainerId -Docker $Docker -Service $Service
    $info = Get-DockerContainerHealth -Docker $Docker -ContainerId $id
    $last = ("id={0} status={1} health={2} running={3}" -f $(if ($id) { $id.Substring(0, [Math]::Min(12, $id.Length)) } else { '-' }), $info.Status, $info.Health, $info.Running)
    if ($info.Health -eq 'healthy') {
      if ($attempt -gt 1) {
        Write-Host ("  {0} healthy after {1} attempt(s)" -f $Name, $attempt) -ForegroundColor DarkGray
      }
      return $true
    }
    if (-not $RequireHealthcheck -and $info.Running -and -not $info.Health) {
      # Service has no HEALTHCHECK — accept running.
      Write-Host ("  {0} running (no HEALTHCHECK)" -f $Name) -ForegroundColor DarkGray
      return $true
    }
    # Published hub images may omit HEALTHCHECK; compose healthcheck needs recreate.
    if ($info.Running -and -not $info.Health -and $HttpFallbackUrl) {
      $probe = Test-HttpOk -Url $HttpFallbackUrl -Method 'GET' -TimeoutMs 3000
      if ($probe.Ok) {
        Write-Host ("  {0} ready via HTTP ({1}) — docker health empty (no HEALTHCHECK in image)" -f $Name, $HttpFallbackUrl) -ForegroundColor DarkGray
        return $true
      }
    }
    if ($attempt -eq 1 -or ($attempt % 5) -eq 0) {
      Write-Host ("  waiting {0}: {1}" -f $Name, $last) -ForegroundColor DarkGray
    }
    Start-Sleep -Seconds 3
  }
  Write-Host ("  {0} give up: {1}" -f $Name, $last) -ForegroundColor Yellow
  return $false
}

function Test-DockerDaemon {
  $docker = Get-Tool @('docker')
  if (-not $docker) { return $false }
  $oldEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  & $docker info 1>$null 2>$null
  $code = $LASTEXITCODE
  $ErrorActionPreference = $oldEap
  return ($code -eq 0)
}

function Invoke-StandComposeUp {
  $docker = Get-Tool @('docker')
  if (-not $docker) {
    Add-Result -Name 'stand.compose' -Status SKIP -Detail 'docker not in PATH'
    return $false
  }

  if (-not (Test-DockerDaemon)) {
    Add-Result -Name 'stand.docker' -Status FAIL -Detail 'Docker daemon not running. Start Docker Desktop, then re-run .\db-tests.ps1'
    return $false
  }
  Add-Result -Name 'stand.docker' -Status PASS -Detail 'daemon reachable'

  Write-Host ""
  Write-Host ("=== stand compose up ({0}) ===" -f $Stand) -ForegroundColor Cyan

  # Free ports: stop every running container (no down -v — keep volumes).
  $oldEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $running = @(& $docker ps -q 2>$null)
  $ErrorActionPreference = $oldEap
  if ($running.Count -gt 0) {
    [void](Invoke-Logged -Name 'stand.stop-all' -File $docker -WorkDir $Root -LogName 'stand-stop-all.log' -Arguments (@('stop') + $running))
  } else {
    Add-Result -Name 'stand.stop-all' -Status SKIP -Detail 'no running containers'
  }

  # Shared container_name (traefik, client-postgresdb17, airflow-*) collide when switching
  # dbpsql <-> dbmssql after a mere `docker stop`. Tear down both compose projects (keep volumes).
  $dbProjectsRoot = Join-Path (Join-Path $Root 'src') 'dbprojects'
  foreach ($proj in @('dbpsql', 'dbmssql')) {
    $otherCompose = Join-Path (Join-Path $dbProjectsRoot $proj) 'docker-compose.yml'
    if (-not (Test-Path -LiteralPath $otherCompose)) { continue }
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $downOut = & $docker compose -p $proj -f $otherCompose down --remove-orphans 2>&1
    $downCode = $LASTEXITCODE
    $ErrorActionPreference = $oldEap
    $downOut | Out-File -FilePath (Join-Path $RunDir ("stand-down-{0}.log" -f $proj)) -Encoding UTF8
    if ($downCode -ne 0) {
      Write-Host ("  compose down {0}: exit {1} (see stand-down-{0}.log)" -f $proj, $downCode) -ForegroundColor DarkYellow
    }
  }

  # Do not use --wait on the whole stack: airflow-dag-processor healthcheck is flaky
  # and blocks even when MQ / Airflow API are already usable for General tests.
  $upArgs = @('compose', '-p', $Stand, '-f', $ComposeFile, 'up', '-d')
  if ($Build) {
    $upArgs = @('compose', '-p', $Stand, '-f', $ComposeFile, 'up', '-d', '--build')
  }

  $ok = Invoke-Logged -Name 'stand.compose-up' -File $docker -WorkDir $StandDir -LogName 'stand-up.log' -Arguments $upArgs
  if (-not $ok) { return $false }

  if (Wait-DockerHealthy -Docker $docker -Service 'mq.webservice' -Name 'mq' -TimeoutSec $ReadyTimeoutSec -RequireHealthcheck -HttpFallbackUrl ($MqBaseUrl.TrimEnd('/') + '/v1/mq/health/live')) {
    Add-Result -Name 'stand.mq-ready' -Status PASS -Detail 'docker health=healthy (mq.webservice)'
  } else {
    Add-Result -Name 'stand.mq-ready' -Status FAIL -Detail ("mq.webservice not healthy within {0}s" -f $ReadyTimeoutSec)
    return $false
  }

  if (Wait-DockerHealthy -Docker $docker -Service 'api-server' -Name 'airflow' -TimeoutSec $ReadyTimeoutSec -RequireHealthcheck) {
    Add-Result -Name 'stand.airflow-ready' -Status PASS -Detail 'docker health=healthy (api-server)'
  } else {
    Add-Result -Name 'stand.airflow-ready' -Status FAIL -Detail ("api-server not healthy within {0}s" -f $ReadyTimeoutSec)
    return $false
  }

  return $true
}

function Ensure-MqRunning {
  $statusUrl = ($MqBaseUrl.TrimEnd('/') + '/v1/mq/service/status')
  $r = Test-HttpOk -Url $statusUrl -TimeoutMs 8000
  if ($r.Ok) {
    Add-Result -Name 'general.mq-status' -Status PASS -Detail 'already running'
    return $true
  }
  $startUrl = ($MqBaseUrl.TrimEnd('/') + '/v1/mq/service/start')
  $s = Test-HttpOk -Url $startUrl -Method 'POST' -TimeoutMs 60000
  if (-not $s.Ok) {
    Add-Result -Name 'general.mq-start' -Status FAIL -Detail $s.Detail
    return $false
  }
  Start-Sleep -Seconds 3
  $r2 = Test-HttpOk -Url $statusUrl -TimeoutMs 8000
  if ($r2.Ok) {
    Add-Result -Name 'general.mq-start' -Status PASS -Detail 'started'
    return $true
  }
  Add-Result -Name 'general.mq-start' -Status FAIL -Detail ('status after start: {0}' -f $r2.Detail)
  return $false
}

function Invoke-GeneralPipeline {
  Write-Host ""
  Write-Host '=== General: MQ → odins → Airflow staging → DWH target ===' -ForegroundColor Cyan

  # Baseline DB connectivity
  try {
    $probe = Invoke-SqlScalar -DatabaseKind ods -Sql 'SELECT 1'
    if ($probe -ne '1') { throw "unexpected probe=$probe" }
    Add-Result -Name 'general.db-ods' -Status PASS -Detail ("connected {0}" -f $OdsDb)
  } catch {
    Add-Result -Name 'general.db-ods' -Status FAIL -Detail $_.Exception.Message
    return
  }
  try {
    $probe = Invoke-SqlScalar -DatabaseKind dwh -Sql 'SELECT 1'
    if ($probe -ne '1') { throw "unexpected probe=$probe" }
    Add-Result -Name 'general.db-dwh' -Status PASS -Detail ("connected {0}" -f $DwhDb)
  } catch {
    Add-Result -Name 'general.db-dwh' -Status FAIL -Detail $_.Exception.Message
    return
  }

  # Unresolved MQ seed must exist (engine-specific table)
  try {
    $mqCountRaw = Invoke-SqlScalar -DatabaseKind ods -Sql (& $Engine.GetMsgQueueCountSql)
    $mqCount = 0
    [void][int]::TryParse($mqCountRaw, [ref]$mqCount)
    if ($mqCount -le 0) {
      Add-Result -Name 'general.msgqueue-seed' -Status FAIL -Detail (& $Engine.MsgQueueEmptyHint)
      return
    }
    Add-Result -Name 'general.msgqueue-seed' -Status PASS -Detail ("rows={0}" -f $mqCount)
  } catch {
    Add-Result -Name 'general.msgqueue-seed' -Status FAIL -Detail $_.Exception.Message
    return
  }

  if (-not (Ensure-MqRunning)) { return }

  Write-Host ""
  Write-Host '=== Phase 1: RabbitMQ ← MessageQueue → MQ → odins ===' -ForegroundColor Cyan

  if ($ClearData) {
    try {
      Clear-OdinsTargetTables
      Add-Result -Name 'general.clear-odins' -Status PASS -Detail 'truncated odins entity tables'
    } catch {
      Add-Result -Name 'general.clear-odins' -Status FAIL -Detail $_.Exception.Message
      return
    }
  } else {
    Add-Result -Name 'general.clear-odins' -Status SKIP -Detail 'ClearData off; detect by engine timestamp cols + buffers'
  }

  $beforeCounts = Get-TableCounts -DatabaseKind ods -Schema 'odins' -Tables $OdinsTables
  $beforeBuffers = Get-TableCounts -DatabaseKind ods -Schema 'odins' -Tables $OdinsBufferTables
  Add-Result -Name 'general.odins-before' -Status PASS -Detail ("main={0}; buffer={1}" -f (Format-Counts $beforeCounts), (Format-Counts $beforeBuffers))

  $queueBefore = Get-MsgQueueCount

  $sendUrl = ($MqBaseUrl.TrimEnd('/') + '/v1/mq/service/send-unresolved-msg')
  Write-Host ("POST {0}" -f $sendUrl) -ForegroundColor DarkCyan
  $swSend = [Diagnostics.Stopwatch]::StartNew()
  $send = Test-HttpOk -Url $sendUrl -Method 'POST' -TimeoutMs 600000
  $swSend.Stop()
  if (-not $send.Ok) {
    Add-Result -Name 'general.send-unresolved-msg' -Status FAIL -Detail ("{0} ({1} ms) {2}" -f $send.Detail, $swSend.ElapsedMilliseconds, $send.Body) -Ms $swSend.ElapsedMilliseconds
    return
  }
  Add-Result -Name 'general.send-unresolved-msg' -Status PASS -Detail ("{0}, {1} ms (queue before={2}; MessageQueue is seed — not drained by design)" -f $send.Detail, $swSend.ElapsedMilliseconds, $queueBefore) -Ms $swSend.ElapsedMilliseconds

  # send-unresolved stops MQ, publishes to Rabbit, then Start() — clock from worker listen start
  $marker = $null
  try {
    $marker = Get-DbTimeMarker
  } catch {
    Add-Result -Name 'general.phase1-mq-odins' -Status FAIL -Detail ("marker failed: {0}" -f $_.Exception.Message)
    return
  }
  $swListen = [Diagnostics.Stopwatch]::StartNew()
  Write-Host ("  MQ worker listening — waiting until odins main/buffer catch up (marker={0})" -f $marker) -ForegroundColor DarkGray

  $deadline = (Get-Date).AddSeconds($OdinsTimeoutSec)
  $fresh = $null
  $filled = $false
  $stableHits = 0
  $prevFreshSum = -1
  $afterBuffers = $null
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds $PollSec
    try {
      $fresh = Get-OdinsFreshCounts -Marker $marker
      $afterBuffers = Get-TableCounts -DatabaseKind ods -Schema 'odins' -Tables $OdinsBufferTables
      $freshSum = Get-CountSum $fresh
      $freshTables = Get-PositiveTableCount $fresh
      $bufferGrowth = (Get-CountSum $afterBuffers) - (Get-CountSum $beforeBuffers)
      $bufferTables = Get-PositiveTableCount $afterBuffers
      $elapsedSec = [Math]::Round($swListen.Elapsed.TotalSeconds, 1)
      Write-Host ("  t+{0}s odins fresh: {1}; buffers: {2} (growth={3})" -f $elapsedSec, (Format-Counts $fresh), (Format-Counts $afterBuffers), $bufferGrowth) -ForegroundColor DarkGray

      # Pass when MQ wrote into main (fresh) and/or buffer tables grew — buffer is the durable MQ footprint
      $mqEvidence = ($freshSum -gt 0 -and $freshTables -ge 1) -or ($bufferGrowth -gt 0 -and $bufferTables -ge 1)
      if ($mqEvidence) {
        $signalSum = $freshSum + [Math]::Max(0, $bufferGrowth)
        if ($signalSum -eq $prevFreshSum) {
          $stableHits++
        } else {
          $stableHits = 0
        }
        $prevFreshSum = $signalSum
        if ($stableHits -ge 1) {
          $filled = $true
          break
        }
      } else {
        $prevFreshSum = -1
        $stableHits = 0
      }
    } catch {
      Write-Host ("  odins poll error: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    }
  }
  $swListen.Stop()
  $listenMs = [int]$swListen.ElapsedMilliseconds
  $listenSec = [Math]::Round($swListen.Elapsed.TotalSeconds, 1)

  if (-not $filled) {
    $detail = if ($fresh) { Format-Counts $fresh } else { 'no counts' }
    $bufDetail = if ($afterBuffers) { Format-Counts $afterBuffers } else { 'no buffers' }
    Add-Result -Name 'general.phase1-mq-odins' -Status FAIL -Detail ("timeout {0}s after worker start; fresh: {1}; buffers: {2}" -f $OdinsTimeoutSec, $detail, $bufDetail) -Ms $listenMs
    return
  }

  $afterCounts = Get-TableCounts -DatabaseKind ods -Schema 'odins' -Tables $OdinsTables
  if (-not $afterBuffers) {
    $afterBuffers = Get-TableCounts -DatabaseKind ods -Schema 'odins' -Tables $OdinsBufferTables
  }
  $mainGrowth = (Get-CountSum $afterCounts) - (Get-CountSum $beforeCounts)
  $bufferGrowthFinal = (Get-CountSum $afterBuffers) - (Get-CountSum $beforeBuffers)

  # Hard fail: green without any MQ footprint in ODS (common confusion: empty main after ETL, or wrong engine DB)
  if ($mainGrowth -le 0 -and $bufferGrowthFinal -le 0 -and (Get-CountSum $fresh) -le 0) {
    Add-Result -Name 'general.phase1-mq-odins' -Status FAIL -Detail ("no ODS growth after MQ; main={0}; buffer={1}; engine={2} db={3}" -f (Format-Counts $afterCounts), (Format-Counts $afterBuffers), $Engine.Label, $OdsDb) -Ms $listenMs
    return
  }

  # Prefer evidence that MQ wrote buffers (survives Airflow clearing main odins.*)
  if ($bufferGrowthFinal -le 0 -and (Get-CountSum $afterBuffers) -le 0 -and $mainGrowth -le 0) {
    Add-Result -Name 'general.phase1-mq-odins' -Status FAIL -Detail ("buffers empty and no main growth — Rabbit→ODS likely skipped; check mq logs / RabbitMQSettings__Enabled") -Ms $listenMs
    return
  }

  $phase1Detail = ("Rabbit→odins in {0}s; fresh={1}; main Δ={2} ({3}); buffer Δ={4} ({5})" -f `
    $listenSec, (Format-Counts $fresh), $mainGrowth, (Format-Counts $afterCounts), $bufferGrowthFinal, (Format-Counts $afterBuffers))
  Add-Result -Name 'general.phase1-mq-odins' -Status PASS -Detail $phase1Detail -Ms $listenMs

  $salesParent = [string]$Engine.SalesParentTable
  $salesChild = [string]$Engine.SalesChildTable
  if ($salesParent -and $salesChild -and $afterCounts.Contains($salesParent) -and $afterCounts.Contains($salesChild)) {
    $p = [int]$afterCounts[$salesParent]
    $c = [int]$afterCounts[$salesChild]
    $pf = if ($fresh -and $fresh.Contains($salesParent)) { [int]$fresh[$salesParent] } else { 0 }
    $cf = if ($fresh -and $fresh.Contains($salesChild)) { [int]$fresh[$salesChild] } else { 0 }
    # Main may already be cleared by ETL; treat fresh child or absolute child as evidence
    if (($p -gt 0 -or $pf -gt 0) -and ($c -le 0 -and $cf -le 0)) {
      Add-Result -Name 'general.odins-sales-lines' -Status FAIL -Detail ("parent {0} main/fresh={1}/{2} but child {3} main/fresh={4}/{5}" -f $salesParent, $p, $pf, $salesChild, $c, $cf) -Ms $listenMs
      return
    }
    Add-Result -Name 'general.odins-sales-lines' -Status PASS -Detail ("{0} main/fresh={1}/{2}; {3} main/fresh={4}/{5}" -f $salesParent, $p, $pf, $salesChild, $c, $cf) -Ms $listenMs
  }

  Write-Host ""
  Write-Host ('[PASS] Phase 1: MQ consumed Rabbit and loaded odins in {0}s' -f $listenSec) -ForegroundColor Green
  Write-Host ('       {0}' -f $phase1Detail) -ForegroundColor Green
  Write-Host ('       Note: MessageQueue seed rows stay in mq.*; after Airflow, main odins.* may be 0 — check *_buffer / DWH.') -ForegroundColor DarkGray
  Write-Host ""

  # --- Phase 2–3: Airflow ETL ---
  Write-Host '=== Phase 2–3: Airflow ETL → staging → target ===' -ForegroundColor Cyan
  try {
    $token = Get-AirflowToken
    Add-Result -Name 'general.airflow-token' -Status PASS -Detail ('user={0}' -f $AirflowUser)
  } catch {
    Add-Result -Name 'general.airflow-token' -Status FAIL -Detail $_.Exception.Message
    return
  }

  $dagId = 'dwh_etl_start'
  $unpause = Invoke-AirflowApi -Method 'PATCH' -Path ("/api/v2/dags/{0}" -f $dagId) -Token $token -Body '{"is_paused":false}'
  if (-not $unpause.Ok -and $unpause.Code -ne 409) {
    Write-Host ("  unpause via API: {0} {1}" -f $unpause.Detail, $unpause.Body) -ForegroundColor DarkYellow
  }

  $runId = ('dbtests__{0}' -f $Stamp)
  # Airflow 3: logical_date is required in the body (null = server assigns)
  $triggerBody = ('{{"dag_run_id":"{0}","logical_date":null,"conf":{{}}}}' -f $runId)
  $trigger = Invoke-AirflowApi -Method 'POST' -Path ("/api/v2/dags/{0}/dagRuns" -f $dagId) -Token $token -Body $triggerBody
  if (-not $trigger.Ok) {
    Write-Host ("  trigger API failed: {0} {1}" -f $trigger.Detail, $trigger.Body) -ForegroundColor DarkYellow
    # Fallback: CLI via image entrypoint (bare `airflow` has broken PYTHONPATH in some images)
    $docker = Get-Tool @('docker')
    if (-not $docker) {
      Add-Result -Name 'general.airflow-trigger' -Status FAIL -Detail ("{0} {1}" -f $trigger.Detail, $trigger.Body)
      return
    }
    $okCli = Invoke-Logged -Name 'general.airflow-trigger-cli' -File $docker -WorkDir $StandDir -LogName 'airflow-trigger.log' -Arguments @(
      'compose', '-p', $Stand, '-f', $ComposeFile, 'exec', '-T', 'api-server',
      '/entrypoint', 'airflow', 'dags', 'trigger', $dagId, '--run-id', $runId
    )
    if (-not $okCli) {
      Add-Result -Name 'general.airflow-trigger' -Status FAIL -Detail ("API: {0}; CLI also failed — see airflow-trigger.log" -f $trigger.Detail)
      return
    }
    Add-Result -Name 'general.airflow-trigger' -Status PASS -Detail ("run_id={0} (via CLI)" -f $runId)
  } else {
    Add-Result -Name 'general.airflow-trigger' -Status PASS -Detail ("run_id={0}" -f $runId)
  }

  Write-Host ("  waiting DAG {0} run {1} ..." -f $dagId, $runId) -ForegroundColor DarkGray
  $etlDeadline = (Get-Date).AddSeconds($EtlTimeoutSec)
  $state = 'queued'
  $swEtl = [Diagnostics.Stopwatch]::StartNew()
  while ((Get-Date) -lt $etlDeadline) {
    Start-Sleep -Seconds $PollSec
    $st = Invoke-AirflowApi -Method 'GET' -Path ("/api/v2/dags/{0}/dagRuns/{1}" -f $dagId, [uri]::EscapeDataString($runId)) -Token $token
    if ($st.Ok) {
      try {
        $state = [string](($st.Body | ConvertFrom-Json).state)
      } catch {
        $state = 'unknown'
      }
      Write-Host ("  t+{0}s dag state={1}" -f ([Math]::Round($swEtl.Elapsed.TotalSeconds, 1)), $state) -ForegroundColor DarkGray
      if ($state -in @('success', 'failed', 'skipped')) { break }
    } else {
      Write-Host ("  dag poll: {0} {1}" -f $st.Detail, $st.Body) -ForegroundColor DarkYellow
    }
  }
  $swEtl.Stop()

  if ($state -ne 'success') {
    Add-Result -Name 'general.airflow-etl' -Status FAIL -Detail ("state={0} after {1}s (timeout {2}s)" -f $state, ([Math]::Round($swEtl.Elapsed.TotalSeconds, 1)), $EtlTimeoutSec) -Ms ([int]$swEtl.ElapsedMilliseconds)
    return
  }
  Add-Result -Name 'general.airflow-etl' -Status PASS -Detail ("state=success in {0}s run_id={1}" -f ([Math]::Round($swEtl.Elapsed.TotalSeconds, 1)), $runId) -Ms ([int]$swEtl.ElapsedMilliseconds)
  Write-Host ""
  Write-Host ('[PASS] Phase 2: Airflow dwh_etl_start finished in {0}s' -f ([Math]::Round($swEtl.Elapsed.TotalSeconds, 1))) -ForegroundColor Green
  Write-Host ""

  # Staging after full DAG (transfer fills staging; publish keeps rows)
  try {
    $staging = Get-TableCounts -DatabaseKind dwh -Schema 'staging' -Tables $DwhEntityTables
    $stgSum = 0
    $stgPositive = 0
    foreach ($k in $staging.Keys) {
      $n = [int]$staging[$k]
      $stgSum += $n
      if ($n -gt 0) { $stgPositive++ }
    }
    if ($stgSum -le 0) {
      Add-Result -Name 'general.staging-filled' -Status FAIL -Detail (Format-Counts $staging)
      return
    }
    Add-Result -Name 'general.staging-filled' -Status PASS -Detail ("tables_with_rows={0}; {1}" -f $stgPositive, (Format-Counts $staging))
    Write-Host ('[PASS] Phase 3a: DWH staging has rows ({0} tables)' -f $stgPositive) -ForegroundColor Green
  } catch {
    Add-Result -Name 'general.staging-filled' -Status FAIL -Detail $_.Exception.Message
    return
  }

  try {
    $target = Get-TableCounts -DatabaseKind dwh -Schema 'target' -Tables $DwhEntityTables
    $trgSum = 0
    $trgPositive = 0
    foreach ($k in $target.Keys) {
      $n = [int]$target[$k]
      $trgSum += $n
      if ($n -gt 0) { $trgPositive++ }
    }
    if ($trgSum -le 0) {
      Add-Result -Name 'general.target-filled' -Status FAIL -Detail (Format-Counts $target)
      return
    }
    Add-Result -Name 'general.target-filled' -Status PASS -Detail ("tables_with_rows={0}; {1}" -f $trgPositive, (Format-Counts $target))
    Write-Host ('[PASS] Phase 3b: DWH target has rows ({0} tables)' -f $trgPositive) -ForegroundColor Green

    $salesParent = [string]$Engine.SalesParentTable
    $salesChild = [string]$Engine.SalesChildTable
    if ($salesParent -and $salesChild -and $target.Contains($salesParent) -and $target.Contains($salesChild)) {
      $parentN = [int]$target[$salesParent]
      $childN = [int]$target[$salesChild]
      if ($parentN -gt 0 -and $childN -le 0) {
        Add-Result -Name 'general.target-sales-lines' -Status FAIL -Detail ("{0}={1} but tabular {2}={3} (reports need line items)" -f $salesParent, $parentN, $salesChild, $childN)
        return
      }
      if ($parentN -gt 0) {
        Add-Result -Name 'general.target-sales-lines' -Status PASS -Detail ("{0}={1}, {2}={3}" -f $salesParent, $parentN, $salesChild, $childN)
        Write-Host ('[PASS] Phase 3c: sales lines {0}={1} (parent {2}={3})' -f $salesChild, $childN, $salesParent, $parentN) -ForegroundColor Green
        if ($Engine.GetSalesLinesQualitySql) {
          try {
            $qRaw = Invoke-SqlScalar -DatabaseKind dwh -Sql (& $Engine.GetSalesLinesQualitySql 'target')
            # mssql may return one cell oddly; psql returns rows|with_product|sum_qty
            $parts = ("$qRaw").Trim() -split '\|'
            if ($parts.Count -ge 3) {
              $rowsTotal = 0; $withProd = 0; $sumQty = 0.0
              [void][int]::TryParse($parts[0], [ref]$rowsTotal)
              [void][int]::TryParse($parts[1], [ref]$withProd)
              [void][double]::TryParse($parts[2], [ref]$sumQty)
              if ($rowsTotal -gt 0 -and $withProd -le 0) {
                Add-Result -Name 'general.target-sales-line-fields' -Status FAIL -Detail ("{0} rows={1} but Товар empty (xpath/load bug); sum_qty={2}" -f $salesChild, $rowsTotal, $sumQty)
                return
              }
              Add-Result -Name 'general.target-sales-line-fields' -Status PASS -Detail ("rows={0}, with_Товар={1}, sum_Колличество={2}" -f $rowsTotal, $withProd, $sumQty)
            } else {
              Add-Result -Name 'general.target-sales-line-fields' -Status SKIP -Detail ("unparsed quality: {0}" -f $qRaw)
            }
          } catch {
            Add-Result -Name 'general.target-sales-line-fields' -Status FAIL -Detail $_.Exception.Message
            return
          }
        }
      } else {
        Add-Result -Name 'general.target-sales-lines' -Status SKIP -Detail ("{0}=0" -f $salesParent)
      }
    }
    Write-Host ""
  } catch {
    Add-Result -Name 'general.target-filled' -Status FAIL -Detail $_.Exception.Message
    return
  }
}

# --- Main ---
Write-Host ("db-tests stand={0} All={1} General={2} SkipCompose={3}" -f $Stand, [bool]$All, $runGeneral, [bool]$SkipCompose) -ForegroundColor Cyan
if ($Engine.Label -eq 'mssql') {
  Write-Host ("ODS={0} DWH={1}  engine=SQL Server (sqlcmd → localhost,1433)" -f $OdsDb, $DwhDb) -ForegroundColor DarkCyan
} else {
  Write-Host ("ODS={0} DWH={1}  engine=PostgreSQL (docker → client-postgresdb17)" -f $OdsDb, $DwhDb) -ForegroundColor DarkCyan
}

$standOk = $true
if ($SkipCompose) {
  Add-Result -Name 'stand.compose-up' -Status SKIP -Detail 'SkipCompose'
  $docker = Get-Tool @('docker')
  $liveUrl = ($MqBaseUrl.TrimEnd('/') + '/v1/mq/health/live')
  if (-not $docker -or -not (Test-DockerDaemon)) {
    Add-Result -Name 'stand.mq-ready' -Status FAIL -Detail 'docker not available'
    $standOk = $false
  } else {
    # Prefer compose container for this stand; fall back to HTTP (ports may be from another stand).
    $mqId = Get-ComposeContainerId -Docker $docker -Service 'mq.webservice'
    $liveUrl = ($MqBaseUrl.TrimEnd('/') + '/v1/mq/health/live')
    $httpOk = (Test-HttpOk -Url $liveUrl -Method 'GET' -TimeoutMs 3000).Ok
    if (-not [string]::IsNullOrWhiteSpace($mqId)) {
      if (Wait-DockerHealthy -Docker $docker -Service 'mq.webservice' -Name 'mq' -TimeoutSec 60 -RequireHealthcheck -HttpFallbackUrl $liveUrl) {
        Add-Result -Name 'stand.mq-ready' -Status PASS -Detail ("docker health=healthy (compose project {0})" -f $Stand)
      } else {
        Add-Result -Name 'stand.mq-ready' -Status FAIL -Detail ("mq.webservice in project '{0}' is not healthy" -f $Stand)
        $standOk = $false
      }
    } elseif ($httpOk) {
      Add-Result -Name 'stand.mq-ready' -Status FAIL -Detail ("HTTP {0} is up, but mq.webservice is not in compose project '{1}' (another stand owns :8090). Run without -SkipCompose: .\db-tests.ps1 {1}" -f $liveUrl, $Stand)
      $standOk = $false
    } else {
      Add-Result -Name 'stand.mq-ready' -Status FAIL -Detail ("mq.webservice missing for project '{0}'. Start it: .\db-tests.ps1 {0}   (do not use -SkipCompose until that stand is up)" -f $Stand)
      $standOk = $false
    }
  }
} else {
  $standOk = Invoke-StandComposeUp
}

if ($standOk -and $runGeneral) {
  Invoke-GeneralPipeline
} elseif (-not $standOk) {
  Add-Result -Name 'general' -Status SKIP -Detail 'stand not ready'
}

# --- Summary ---
$failCount = @($Results | Where-Object { $_.Status -eq 'FAIL' }).Count
$passCount = @($Results | Where-Object { $_.Status -eq 'PASS' }).Count
$skipCount = @($Results | Where-Object { $_.Status -eq 'SKIP' }).Count

$md = New-Object System.Collections.Generic.List[string]
$md.Add('# DB test report') | Out-Null
$md.Add('') | Out-Null
$md.Add(('Date: `{0}`' -f $Stamp)) | Out-Null
$md.Add(('Stand: `{0}`' -f $Stand)) | Out-Null
$md.Add(('ODS / DWH: `{0}` / `{1}`' -f $OdsDb, $DwhDb)) | Out-Null
$md.Add(('Flags: All={0} General={1} SkipCompose={2} Build={3} ClearData={4}' -f [bool]$All, $runGeneral, [bool]$SkipCompose, [bool]$Build, [bool]$ClearData)) | Out-Null
$md.Add('') | Out-Null
$md.Add(('Totals: **PASS {0}** / **FAIL {1}** / **SKIP {2}**' -f $passCount, $failCount, $skipCount)) | Out-Null
$md.Add('') | Out-Null
$md.Add('| Suite | Status | Detail | Log |') | Out-Null
$md.Add('| --- | --- | --- | --- |') | Out-Null
foreach ($row in $Results) {
  $logCell = ''
  if ($row.Log) { $logCell = ('[{0}]({0})' -f (Split-Path $row.Log -Leaf)) }
  $detail = ([string]$row.Detail) -replace '\|', '/'
  $md.Add(('| {0} | {1} | {2} | {3} |' -f $row.Name, $row.Status, $detail, $logCell)) | Out-Null
}

$summaryPath = Join-Path $RunDir 'summary.md'
$latestPath = Join-Path $ReportRoot ('latest-db-{0}.md' -f $Stand)
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($summaryPath, $md, $utf8)
Copy-Item -Force $summaryPath $latestPath

Write-Host ""
Write-Host ('Report: {0}' -f $RunDir) -ForegroundColor Cyan
Write-Host ('Latest: {0}' -f $latestPath) -ForegroundColor Cyan
Write-Host ('PASS={0} FAIL={1} SKIP={2}' -f $passCount, $failCount, $skipCount)

if ($failCount -gt 0) {
  exit 1
}
exit 0
