# function Check-ModuleVersionStatus {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string[]]$ModuleNames
#     )

#     Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue

#     foreach ($ModuleName in $ModuleNames) {
#         try {
#             $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
#             $latestModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue

#             if ($installedModule -and $latestModule) {
#                 if ($installedModule.Version -lt $latestModule.Version) {
#                     Write-Host "Module '$ModuleName' is outdated. Installed version: $($installedModule.Version). Latest version: $($latestModule.Version)." -ForegroundColor Red
#                 } else {
#                     Write-Host "Module '$ModuleName' is up-to-date with the latest version: $($installedModule.Version)." -ForegroundColor Green
#                 }
#             } elseif (-not $installedModule) {
#                 Write-Host "Module '$ModuleName' is not installed." -ForegroundColor Yellow
#             } else {
#                 Write-Host "Unable to find '$ModuleName' in the PowerShell Gallery." -ForegroundColor Yellow
#             }
#         } catch {
#             Write-Error "An error occurred checking module '$ModuleName': $_"
#         }
#     }
# }


# # Check-ModuleVersionStatus -ModuleNames @('Pester', 'AzureRM', 'PowerShellGet')
# # Check-ModuleVersionStatus -ModuleNames @('Pester')





# function Check-ModuleVersionStatus {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string[]]$ModuleNames
#     )

#     Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue

#     $results = @()  # Initialize an array to hold the results

#     foreach ($ModuleName in $ModuleNames) {
#         try {
#             $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
#             $latestModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue

#             if ($installedModule -and $latestModule) {
#                 if ($installedModule.Version -lt $latestModule.Version) {
#                     $results += [PSCustomObject]@{
#                         ModuleName = $ModuleName
#                         Status = "Outdated"
#                         InstalledVersion = $installedModule.Version
#                         LatestVersion = $latestModule.Version
#                     }
#                 } else {
#                     $results += [PSCustomObject]@{
#                         ModuleName = $ModuleName
#                         Status = "Up-to-date"
#                         InstalledVersion = $installedModule.Version
#                         LatestVersion = $installedModule.Version
#                     }
#                 }
#             } elseif (-not $installedModule) {
#                 $results += [PSCustomObject]@{
#                     ModuleName = $ModuleName
#                     Status = "Not Installed"
#                     InstalledVersion = $null
#                     LatestVersion = $null
#                 }
#             } else {
#                 $results += [PSCustomObject]@{
#                     ModuleName = $ModuleName
#                     Status = "Not Found in Gallery"
#                     InstalledVersion = $null
#                     LatestVersion = $null
#                 }
#             }
#         } catch {
#             Write-Error "An error occurred checking module '$ModuleName': $_"
#         }
#     }

#     return $results
# }

# Example usage:
# $versionStatuses = Check-ModuleVersionStatus -ModuleNames @('Pester', 'AzureRM', 'PowerShellGet')
# $versionStatuses | Format-Table -AutoSize  # Display the results in a table format for readability










# function Check-SystemWideModule {
#     param (
#         [string]$ModuleName
#     )

#     # Save the current PSModulePath and then modify it
#     $originalPSModulePath = $env:PSModulePath
#     try {
#         # Set PSModulePath to only system-wide directories (for both PS5 and PS7)
#         $systemPaths = @(
#             "C:\Program Files\WindowsPowerShell\Modules",
#             "C:\Windows\system32\WindowsPowerShell\v1.0\Modules",
#             "C:\Program Files\PowerShell\Modules",
#             "c:\program files\powershell\7\Modules"
#         )
        
#         # Filter out paths that do not exist to avoid errors
#         $existingSystemPaths = $systemPaths | Where-Object { Test-Path $_ }

#         # Join the paths into a single string separated by semicolons
#         $env:PSModulePath = $existingSystemPaths -join ';'

#         # Now get the module, only from the specified paths
#         $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1

#         if ($installedModule) {
#             Write-Host "Found $($ModuleName) version $($installedModule.Version) in system-wide directory."
#         } else {
#             Write-Host "$ModuleName not found in system-wide directories."
#         }
#     } finally {
#         # Restore the original PSModulePath
#         $env:PSModulePath = $originalPSModulePath
#     }
# }

# Example usage
# Check-SystemWideModule -ModuleName 'Pester'







function Check-ModuleVersionStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ModuleNames
    )

    #the following modules PowerShellGet and PackageManagement has to be either automatically imported or manually imported into C:\windows\System32\WindowsPowerShell\v1.0\Modules

    Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue
    # Import-Module 'C:\Program Files (x86)\WindowsPowerShell\Modules\PowerShellGet\PSModule.psm1' -ErrorAction SilentlyContinue
    # Import-Module 'C:\windows\System32\WindowsPowerShell\v1.0\Modules\PowerShellGet\PSModule.psm1' -ErrorAction SilentlyContinue
    # Import-Module 'C:\Program Files (x86)\WindowsPowerShell\Modules\PackageManagement\PackageProviderFunctions.psm1' -ErrorAction SilentlyContinue
    # Import-Module 'C:\windows\System32\WindowsPowerShell\v1.0\Modules\PackageManagement\PackageProviderFunctions.psm1' -ErrorAction SilentlyContinue
    # Import-Module 'C:\Program Files (x86)\WindowsPowerShell\Modules\PackageManagement\PackageManagement.psm1' -ErrorAction SilentlyContinue

    $results = New-Object System.Collections.Generic.List[PSObject]  # Initialize a List to hold the results

    foreach ($ModuleName in $ModuleNames) {
        try {

            Write-Host 'Checking module '$ModuleName
            $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
            # $installedModule = Check-SystemWideModule -ModuleName 'Pester'
            $latestModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue

            if ($installedModule -and $latestModule) {
                if ($installedModule.Version -lt $latestModule.Version) {
                    $results.Add([PSCustomObject]@{
                        ModuleName = $ModuleName
                        Status = "Outdated"
                        InstalledVersion = $installedModule.Version
                        LatestVersion = $latestModule.Version
                    })
                } else {
                    $results.Add([PSCustomObject]@{
                        ModuleName = $ModuleName
                        Status = "Up-to-date"
                        InstalledVersion = $installedModule.Version
                        LatestVersion = $installedModule.Version
                    })
                }
            } elseif (-not $installedModule) {
                $results.Add([PSCustomObject]@{
                    ModuleName = $ModuleName
                    Status = "Not Installed"
                    InstalledVersion = $null
                    LatestVersion = $null
                })
            } else {
                $results.Add([PSCustomObject]@{
                    ModuleName = $ModuleName
                    Status = "Not Found in Gallery"
                    InstalledVersion = $null
                    LatestVersion = $null
                })
            }
        } catch {
            Write-Error "An error occurred checking module '$ModuleName': $_"
        }
    }

    return $results
}

# Example usage:
# $versionStatuses = Check-ModuleVersionStatus -ModuleNames @('Pester', 'AzureRM', 'PowerShellGet')
# $versionStatuses | Format-Table -AutoSize  # Display the results in a table format for readability


