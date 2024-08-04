Install-Module -Name EnhancedBoilerPlateAO -Scope AllUsers -Force
Install-Module -Name EnhancedLoggingAO -Scope AllUsers -Force

Write-EnhancedLog "Logging works" -Level "INFO"

Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))