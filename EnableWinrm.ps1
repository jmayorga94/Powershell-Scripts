
Write-Host "Setting net connection private"
Set-NetConnectionProfile private

Write-Host "Enabling WinRM "
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

Write-Host "Starting WinRM "
Start-Service WinRM
set-service WinRM -StartupType Automatic

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled false
