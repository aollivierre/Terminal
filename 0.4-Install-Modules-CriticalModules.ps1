#for the followint take a snaptshot of a test VM first and try it because it might break these critical modules and if it does break them then you need to bring these two modules from other external sources like GitHub


Install-Module -Name EnhancedBoilerPlateAO -Scope AllUsers -Force
Install-Module -Name EnhancedLoggingAO -Scope AllUsers -Force
Install-Module -Name EnhancedSchedTaskAO  -Scope AllUsers -Force

Write-EnhancedLog "Logging works" -Level "INFO"

CheckAndElevate
function Remove-OldVersions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    Process {
        # Get all versions except the latest one
        $allVersions = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version
        $latestVersion = $allVersions | Select-Object -Last 1
        $olderVersions = $allVersions | Where-Object { $_.Version -ne $latestVersion.Version }

        foreach ($version in $olderVersions) {
            try {
                Write-Host "Removing older version $($version.Version) of $ModuleName..."
                $modulePath = $version.ModuleBase
                Remove-Item -Path $modulePath -Recurse -Force
                # Assuming administrative access for module management
                #  $modulePath = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
                Write-Host "starting takeown and icacls of $modulePath"
                Write-Host "checking and elevating to admin if needed"
                CheckAndElevate
                & takeown.exe /F $modulePath /A /R
                & icacls.exe $modulePath /reset
                & icacls.exe $modulePath /grant "*S-1-5-32-544:F" /inheritance:d /T
                Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false

                Write-Host "Removed $($version.Version) successfully." -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to remove version $($version.Version) of $ModuleName at $modulePath. Error: $_"
            }
        }
    }
}

function Update-CriticalModules {
    [CmdletBinding()]
    param ()

    Begin {
        $criticalModules = @('PowerShellGet', 'PackageManagement')
        # Write-Host "Starting update process for critical modules..." -ForegroundColor Cyan
        Write-Host "Starting update process for critical modules... $criticalModules" -ForegroundColor Cyan
    }

    Process {
        $statusList = Check-ModuleVersionStatus -ModuleNames $criticalModules
        foreach ($status in $statusList) {
            switch ($status.Status) {
                "Outdated" {
                    Write-Host "$($status.ModuleName) is outdated. Current version: $($status.InstalledVersion). Latest available: $($status.LatestVersion)" -ForegroundColor Yellow

                    try {
                        # Install-Module -Name $status.ModuleName -Force -SkipPublisherCheck -AllowClobber
                        Install-Module -Name $status.ModuleName -Force -SkipPublisherCheck -AllowClobber -Scope AllUsers
                        Write-Host "Updated $($status.ModuleName) to the latest version. Verifying update..." -ForegroundColor Green

                        # Re-check the module version to confirm the update was successful
                        $verificationStatus = Check-ModuleVersionStatus -ModuleNames @($status.ModuleName)
                        if ($verificationStatus.Status -eq "Up-to-date") {
                            Write-Host "Verification successful. Removing older versions..." -ForegroundColor Green
                            Remove-OldVersions -ModuleName $status.ModuleName
                        }
                        else {
                            Write-Warning "Verification failed. Update may not have been successful."
                        }
                    }
                    catch {
                        Write-Error "An error occurred while updating $($status.ModuleName): $_"
                    }
                }
                "Up-to-date" {
                    Write-Host "$($status.ModuleName) is up-to-date." -ForegroundColor Green
                    Remove-OldVersions -ModuleName $status.ModuleName
                }
                "Not Installed" {
                    try {
                        Install-Module -Name $status.ModuleName -Force -SkipPublisherCheck -AllowClobber -Scope AllUsers
                        Write-Host "Installed $($status.ModuleName) as it was not previously installed." -ForegroundColor Green
                    }
                    catch {
                        Write-Error "An error occurred while installing $($status.ModuleName): $_"
                    }
                }
            }
        }
    }

    End {
        Write-Host "Update process for critical modules completed." -ForegroundColor Cyan
    }
}

Update-CriticalModules