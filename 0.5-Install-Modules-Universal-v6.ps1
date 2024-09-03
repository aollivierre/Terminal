# Install-Module -Name EnhancedBoilerPlateAO -Scope AllUsers -Force
# Install-Module -Name EnhancedLoggingAO -Scope AllUsers -Force
# Install-Module -Name EnhancedSchedTaskAO  -Scope AllUsers -Force

# Write-EnhancedLog "Logging works" -Level "INFO"


# Fetch the script content
$scriptContent = Invoke-RestMethod "https://raw.githubusercontent.com/aollivierre/module-starter/main/Module-Starter.ps1"

# Define replacements in a hashtable
$replacements = @{
    '\$Mode = "dev"'                     = '$Mode = "dev"'
    '\$SkipPSGalleryModules = \$false'   = '$SkipPSGalleryModules = $true'
    '\$SkipCheckandElevate = \$false'    = '$SkipCheckandElevate = $true'
    '\$SkipAdminCheck = \$false'         = '$SkipAdminCheck = $true'
    '\$SkipPowerShell7Install = \$false' = '$SkipPowerShell7Install = $true'
    '\$SkipModuleDownload = \$false'     = '$SkipModuleDownload = $true'
}

# Apply the replacements
foreach ($pattern in $replacements.Keys) {
    $scriptContent = $scriptContent -replace $pattern, $replacements[$pattern]
}

# Execute the script
Invoke-Expression $scriptContent

# function Remove-OldVersions {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$ModuleName
#     )

#     Process {
#         # Get all versions except the latest one
#         $allVersions = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version
#         $latestVersion = $allVersions | Select-Object -Last 1
#         $olderVersions = $allVersions | Where-Object { $_.Version -ne $latestVersion.Version }

#         foreach ($version in $olderVersions) {
#             try {
#                 Write-Host "Removing older version $($version.Version) of $ModuleName..."
#                 $modulePath = $version.ModuleBase
#                 # Assuming administrative access for module management
#                 #  $modulePath = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
#                 Write-Host "starting takeown and icacls of $modulePath"
#                 Write-Host "checking and elevating to admin if needed"
#                 CheckAndElevate
#                 & takeown.exe /F $modulePath /A /R
#                 & icacls.exe $modulePath /reset
#                 & icacls.exe $modulePath /grant "*S-1-5-32-544:F" /inheritance:d /T
#                 Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false

#                 Write-Host "Removed $($version.Version) successfully." -ForegroundColor Green
#             }
#             catch {
#                 Write-Error "Failed to remove version $($version.Version) of $ModuleName at $modulePath. Error: $_"
#             }
#         }
#     }
# }
# function Update-ModuleIfOldOrMissing {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$ModuleName
#     )

#     Begin {
#         Write-Host "Starting check and update process for module: $ModuleName..." -ForegroundColor Cyan
#     }

#     Process {
#         $moduleStatus = Check-ModuleVersionStatus -ModuleNames @($ModuleName)
#         foreach ($status in $moduleStatus) {
#             switch ($status.Status) {
#                 "Outdated" {
#                     Write-Host "Updating $ModuleName from version $($status.InstalledVersion) to $($status.LatestVersion)." -ForegroundColor Yellow

#                     # Assuming administrative access for module management
#                     $modulePath = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
#                     & takeown.exe /F $modulePath /A /R
#                     & icacls.exe $modulePath /reset
#                     & icacls.exe $modulePath /grant "*S-1-5-32-544:F" /inheritance:d /T
#                     Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false
#                     # $modulePath = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
#                     # & takeown.exe /F $modulePath /A /R
#                     # & icacls.exe $modulePath /reset
#                     # & icacls.exe $modulePath /grant "*S-1-5-32-544:F" /inheritance:d /T
#                     # Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false


#                     # Re-check the module version to confirm the update was successful
#                     $verificationStatus = Check-ModuleVersionStatus -ModuleNames @($status.ModuleName)
#                     if ($verificationStatus.Status -eq "Up-to-date") {
#                         Write-Host "Verification successful. Removing older versions..." -ForegroundColor Green
#                         Remove-OldVersions -ModuleName $status.ModuleName
#                     }
#                     else {
#                         Write-Warning "Verification failed. Update may not have been successful."
#                     }

#                     # Install the latest version of the module
#                     Install-Module -Name $ModuleName -Force -SkipPublisherCheck -Scope AllUsers
#                     Write-Host "$ModuleName has been updated to the latest version." -ForegroundColor Green
#                 }
#                 "Up-to-date" {
#                     Write-Host "$ModuleName version $($status.InstalledVersion) is up-to-date. No update necessary." -ForegroundColor Green
#                     Remove-OldVersions -ModuleName $status.ModuleName
#                 }
#                 "Not Installed" {
#                     Write-Host "$ModuleName is not installed. Installing the latest version..." -ForegroundColor Yellow
#                     Install-Module -Name $ModuleName -Force -SkipPublisherCheck
#                     Write-Host "$ModuleName has been installed." -ForegroundColor Green
#                 }
#                 "Not Found in Gallery" {
#                     Write-Host "Unable to find '$ModuleName' in the PowerShell Gallery." -ForegroundColor Red
#                 }
#             }
#         }
#     }

#     End {
#         Write-Host "Exiting update function for module: $ModuleName." -ForegroundColor Cyan
#     }
# }

# Example invocation to update or install Pester:
Update-ModuleIfOldOrMissing -ModuleName 'Pester'
Update-ModuleIfOldOrMissing -ModuleName 'PSReadLine'