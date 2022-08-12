[CmdletBinding()]
param (
   [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$AZP_URL,
   [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$AZP_TOKEN,
   [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$AZP_AGENT_NAME,
   [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$AZP_POOL)
  
  $AZP_TOKEN_FILE = "C:/azp/.token"
  $AZP_TOKEN | Out-File -FilePath $AZP_TOKEN_FILE
  
  Write-Host "1. Determining matching Azure Pipelines agent..." -ForegroundColor Cyan
  
  $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content $AZP_TOKEN_FILE)"))
  $package = Invoke-RestMethod -Headers @{Authorization=("Basic $base64AuthInfo")} "$($AZP_URL)/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
  $packageUrl = $package[0].Value.downloadUrl
  
  Write-Host $packageUrl
  $agent_id = New-Guid

  Write-Host "2. Downloading and installing Azure Pipelines agent..." -ForegroundColor Cyan
  
  $wc = New-Object System.Net.WebClient
  $wc.DownloadFile($packageUrl, "$(Get-Location)/agent.zip")
  
  Expand-Archive -Path "agent.zip" -DestinationPath "C:/azp/agent"
  
  Set-Location "C:/azp/agent"

  try
  {
    Write-Host "3. Configuring Azure Pipelines agent..." -ForegroundColor Cyan
  
    .\config.cmd --unattended `
      --agent "$AZP_AGENT_NAME" `
      --url "$AZP_URL" `
      --auth PAT `
      --token "$(Get-Content $AZP_TOKEN_FILE)" `
      --pool "$(if ($AZP_POOL) { $AZP_POOL} else { 'Default' })" `
      --work "$(if ($AZP_WORK) { $AZP_WORK} else { '_work' })" `
      --runAsService `
      --replace
  
    Write-Host "4. Running Azure Pipelines agent..." -ForegroundColor Cyan
  
    .\run.cmd
  }
  finally
  {
    Write-Host "Cleanup. Removing Azure Pipelines agent..." -ForegroundColor Cyan
  
    .\config.cmd remove --unattended `
      --auth PAT `
      --token "$(Get-Content $AZP_TOKEN_FILE)"
  }

