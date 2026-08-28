#Requires -Version 5.1
<#
.SYNOPSIS
  Upload Portal Helper RAG markdown into AnythingLLM workspace and embed.

.DESCRIPTION
  1) Optionally runs export-portal-rag.mjs
  2) Ensures workspace exists (POST /api/v1/workspace/new)
  3) Uploads each .md (POST /api/v1/document/upload)
  4) Adds embeddings (POST /api/v1/workspace/{slug}/update-embeddings)

.EXAMPLE
  $env:ANYTHINGLLM_API_KEY = 'XXXX-XXXX-XXXX-XXXX'
  .\upload-portal-rag.ps1 -BaseUrl 'https://prod26.neva.loc/nevaaichat'

.EXAMPLE
  .\upload-portal-rag.ps1 -BaseUrl 'http://127.0.0.1:3001' -SkipExport
#>
param(
  [string]$BaseUrl = $(if ($env:ANYTHINGLLM_BASE_URL) { $env:ANYTHINGLLM_BASE_URL } else { 'http://127.0.0.1:3001' }),
  [string]$ApiKey = $env:ANYTHINGLLM_API_KEY,
  [string]$WorkspaceName = 'Neva Portal Helper',
  [string]$WorkspaceSlug = 'neva-portal-helper',
  [switch]$SkipExport,
  [switch]$SkipEmbed
)

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot
$RepoAnything = Split-Path $ScriptDir -Parent
$PortalDir = Join-Path $RepoAnything 'rag\portal'
$ExportJs = Join-Path $ScriptDir 'export-portal-rag.mjs'

if (-not $ApiKey) {
  throw 'Set ANYTHINGLLM_API_KEY or pass -ApiKey (Developer API key from AnythingLLM settings).'
}

$BaseUrl = $BaseUrl.TrimEnd('/')

function Invoke-Allm {
  param(
    [string]$Method,
    [string]$Path,
    [object]$Body = $null,
    [string]$ContentType = 'application/json'
  )
  $headers = @{
    Authorization = "Bearer $ApiKey"
    Accept        = 'application/json'
  }
  $uri = "$BaseUrl$Path"
  if ($null -eq $Body) {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
  }
  if ($ContentType -eq 'multipart/form-data') {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Form $Body
  }
  $json = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 8 -Compress }
  return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
}

if (-not $SkipExport) {
  Write-Host '==> Export Astro → Markdown' -ForegroundColor Cyan
  node $ExportJs
  if ($LASTEXITCODE -ne 0) { throw "export-portal-rag.mjs failed: $LASTEXITCODE" }
}

if (-not (Test-Path $PortalDir)) {
  throw "Portal corpus not found: $PortalDir"
}

Write-Host "==> Ensure workspace '$WorkspaceName' (slug=$WorkspaceSlug)" -ForegroundColor Cyan
$existing = $null
try {
  $existing = Invoke-Allm -Method GET -Path "/api/v1/workspace/$WorkspaceSlug"
} catch {
  $existing = $null
}

if (-not $existing -or -not $existing.workspace) {
  try {
    Invoke-Allm -Method POST -Path '/api/v1/workspace/new' -Body @{
      name = $WorkspaceName
      # slug may be auto-derived from name; some versions accept openAiTemp etc. later in UI
    } | Out-Null
    Write-Host "[ok] workspace created (check slug in UI if embed fails)" -ForegroundColor Green
  } catch {
    Write-Host "[warn] workspace/new: $($_.Exception.Message) — continue if already exists" -ForegroundColor Yellow
  }
} else {
  Write-Host '[ok] workspace already exists' -ForegroundColor Green
}

# Collect markdown (skip eval-questions — not for embedding)
$mdFiles = Get-ChildItem -Path $PortalDir -Recurse -Filter '*.md' |
  Where-Object { $_.Name -ne 'eval-questions.md' }

Write-Host "==> Upload $($mdFiles.Count) markdown files" -ForegroundColor Cyan
$locations = New-Object System.Collections.Generic.List[string]

foreach ($f in $mdFiles) {
  Write-Host "  upload $($f.FullName.Substring($PortalDir.Length + 1))"
  # PowerShell 7+ -Form; fallback for Windows PowerShell 5.1
  $uri = "$BaseUrl/api/v1/document/upload"
  if ($PSVersionTable.PSVersion.Major -ge 7) {
    $resp = Invoke-RestMethod -Method POST -Uri $uri -Headers @{
      Authorization = "Bearer $ApiKey"
      Accept        = 'application/json'
    } -Form @{ file = Get-Item -Path $f.FullName }
  } else {
    Add-Type -AssemblyName System.Net.Http
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.DefaultRequestHeaders.Authorization =
      [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $ApiKey)
    $multipart = [System.Net.Http.MultipartFormDataContent]::new()
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $fileContent = [System.Net.Http.ByteArrayContent]::new($bytes)
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('text/markdown')
    $multipart.Add($fileContent, 'file', $f.Name)
    $task = $client.PostAsync($uri, $multipart)
    $task.Wait()
    $raw = $task.Result.Content.ReadAsStringAsync().Result
    if (-not $task.Result.IsSuccessStatusCode) {
      throw "Upload failed $($f.Name): $($task.Result.StatusCode) $raw"
    }
    $resp = $raw | ConvertFrom-Json
    $client.Dispose()
  }

  if ($resp.documents) {
    foreach ($d in $resp.documents) {
      if ($d.location) { [void]$locations.Add($d.location) }
    }
  } elseif ($resp.location) {
    [void]$locations.Add($resp.location)
  } else {
    Write-Host "  [warn] no location in response for $($f.Name): $($resp | ConvertTo-Json -Compress)" -ForegroundColor Yellow
  }
}

Write-Host "==> Uploaded locations: $($locations.Count)" -ForegroundColor Cyan
$locations | ForEach-Object { Write-Host "  $_" }

if ($SkipEmbed) {
  Write-Host 'SkipEmbed set — add documents to workspace in UI or re-run without -SkipEmbed.' -ForegroundColor Yellow
  exit 0
}

if ($locations.Count -eq 0) {
  throw 'No document locations to embed.'
}

Write-Host "==> Embed into workspace $WorkspaceSlug" -ForegroundColor Cyan
Invoke-Allm -Method POST -Path "/api/v1/workspace/$WorkspaceSlug/update-embeddings" -Body @{
  adds = @($locations)
} | Out-Null

Write-Host ''
Write-Host 'Done. In AnythingLLM UI:' -ForegroundColor Green
Write-Host "  1) Open workspace '$WorkspaceName'"
Write-Host '  2) Paste system prompt from rag/portal/_curated/system-prompt.txt'
Write-Host '  3) Chat mode: query; temperature ~0.3'
Write-Host '  4) Run eval-questions.md'
Write-Host ''
$promptFile = Join-Path $PortalDir '_curated\system-prompt.txt'
if (Test-Path $promptFile) {
  Write-Host '--- system prompt ---' -ForegroundColor DarkGray
  Get-Content $promptFile -Raw
}
