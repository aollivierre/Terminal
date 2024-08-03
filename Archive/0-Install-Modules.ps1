# function Install-MissingModules {
#     <#
# .SYNOPSIS
# Installs missing PowerShell modules from a given list of module names.

# .DESCRIPTION
# The Install-MissingModules function checks a list of PowerShell module names and installs any that are not already installed on the system. This function requires administrative privileges to install modules for all users.

# .PARAMETER RequiredModules
# An array of module names that you want to ensure are installed on the system.

# .EXAMPLE
# PS> $modules = @('ImportExcel', 'powershell-yaml')
# PS> Install-MissingModules -RequiredModules $modules

# This example checks for the presence of the 'ImportExcel' and 'powershell-yaml' modules and installs them if they are not already installed.
# #>


#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string[]]$RequiredModules
#     )

#     Begin {
#         Write-Verbose "Starting to check and install required modules..."
#     }

#     Process {
#         foreach ($module in $RequiredModules) {
#             if (-not (Get-Module -ListAvailable -Name $module)) {
#                 Write-Host "Module '$module' is not installed. Attempting to install..."
#                 try {
#                     Install-Module -Name $module -Force -Scope AllUsers
#                     Write-Host "Module '$module' installed successfully."
#                 }
#                 catch {
#                     Write-Error "Failed to install module '$module'. Error: $_"
#                 }
#             }
#             else {
#                 Write-Host "Module '$module' is already installed."
#             }
#         }
#     }

#     End {
#         Write-Verbose "Completed checking and installing modules."
#     }
# }

# # Example usage
# # $modules = @('ImportExcel', 'powershell-yaml' , 'MarkdownModule')
# $modules = @('ImportExcel', 'powershell-yaml' , 'PSWriteHTML')
# Install-MissingModules -RequiredModules $modules -Verbose






















# function Install-MissingModules {
#     <#
#     .SYNOPSIS
#     Installs missing PowerShell modules from a given list of module names and updates them if a new version is available.

#     .DESCRIPTION
#     The Install-MissingModules function checks a list of PowerShell module names, installs any that are not already installed, and updates those that have new versions available on the repository. This function requires administrative privileges to install and update modules for all users.

#     .PARAMETER RequiredModules
#     An array of module names that you want to ensure are installed and up-to-date on the system.

#     .EXAMPLE
#     PS> $modules = @('ImportExcel', 'powershell-yaml', 'z', 'terminal-icons')
#     PS> Install-MissingModules -RequiredModules $modules

#     This example checks for the presence and updates of the 'ImportExcel', 'powershell-yaml', 'z', and 'terminal-icons' modules, installing or updating them as necessary.
#     #>

#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string[]]$RequiredModules
#     )

#     Begin {
#         Write-Verbose "Starting to check, install, and update required modules..."
#     }

#     Process {
#         foreach ($module in $RequiredModules) {
#             $installedModule = Get-Module -ListAvailable -Name $module
#             if (-not $installedModule) {
#                 Write-Host "Module '$module' is not installed. Attempting to install..."
#                 try {
#                     Install-Module -Name $module -Force -Scope AllUsers
#                     Write-Host "Module '$module' installed successfully."
#                 }
#                 catch {
#                     Write-Error "Failed to install module '$module'. Error: $_"
#                 }
#             }
#             else {
#                 Write-Host "Module '$module' is already installed. Checking for updates..."
#                 try {
#                     Update-Module -Name $module -Force
#                     Write-Host "Module '$module' updated successfully."
#                 }
#                 catch {
#                     Write-Error "Failed to update module '$module'. Error: $_"
#                 }
#             }
#         }
#     }

#     End {
#         Write-Verbose "Completed checking, installing, and updating modules."
#     }
# }

# # Example usage
# $modules = @('z', 'terminal-icons')
# Install-MissingModules -RequiredModules $modules -Verbose

























# function InstallAndUpdateModules {
#     <#
#     .SYNOPSIS
#     Installs missing PowerShell modules and updates all installed modules.

#     .DESCRIPTION
#     The InstallAndUpdateModules function checks a list of PowerShell module names, installs any that are not already installed, and updates all modules currently installed on the system. This function requires administrative privileges to install modules and apply updates.

#     .PARAMETER RequiredModules
#     An array of module names that you want to ensure are installed on the system.

#     .EXAMPLE
#     PS> $modules = @('ImportExcel', 'powershell-yaml', 'z', 'terminal-icons')
#     PS> InstallAndUpdateModules -RequiredModules $modules

#     This example installs and updates the specified modules and then updates all other installed modules.
#     #>

#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string[]]$RequiredModules
#     )

#     Begin {
#         Write-Verbose "Starting to check, install, and update required modules..."
#     }

#     Process {
#         # Install or update specified modules
#         foreach ($module in $RequiredModules) {
#             $installedModule = Get-Module -ListAvailable -Name $module
#             if (-not $installedModule) {
#                 Write-Host "Module '$module' is not installed. Attempting to install..."
#                 try {
#                     Install-Module -Name $module -Force -Scope AllUsers
#                     Write-Host "Module '$module' installed successfully."
#                 }
#                 catch {
#                     Write-Error "Failed to install module '$module'. Error: $_"
#                 }
#             } else {
#                 Write-Host "Module '$module' is already installed. Checking for updates..."
#                 try {
#                     Update-Module -Name $module -Force
#                     Write-Host "Module '$module' updated successfully."
#                 }
#                 catch {
#                     Write-Error "Failed to update module '$module'. Error: $_"
#                 }
#             }
#         }

#         # Update all installed modules
#         Write-Host "Updating all installed modules..."
#         $allModules = Get-Module -ListAvailable | Select-Object -Unique -ExpandProperty Name
#         foreach ($mod in $allModules) {
#             try {
#                 Update-Module -Name $mod -Force
#                 Write-Host "Updated module '$mod' successfully."
#             }
#             catch {
#                 Write-Error "Failed to update module '$mod'. Error: $_"
#             }
#         }
#     }

#     End {
#         Write-Verbose "Completed installing and updating modules."
#     }
# }

# # Example usage
# $modules = @('z', 'terminal-icons')
# InstallAndUpdateModules -RequiredModules $modules -Verbose

















function InstallAndUpdateModules {
    <#
    .SYNOPSIS
    Installs missing PowerShell modules and updates all installed modules from the PowerShell Gallery.

    .DESCRIPTION
    This function checks a list of PowerShell module names, installs any that are not already installed, and updates all modules installed from the PowerShell Gallery on the system. This function requires administrative privileges to install modules and apply updates.

    .PARAMETER RequiredModules
    An array of module names that you want to ensure are installed and up-to-date on the system.

    .EXAMPLE
    PS> $modules = @('ImportExcel', 'powershell-yaml', 'z', 'terminal-icons')
    PS> InstallAndUpdateModules -RequiredModules $modules

    This example installs and updates the specified modules, then updates all other installed modules that were installed from the PowerShell Gallery.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$RequiredModules
    )

    Begin {
        Write-Verbose "Starting to check, install, and update required modules..."
    }

    Process {
        # Install or update specified modules
        foreach ($module in $RequiredModules) {
            $installedModule = Get-Module -ListAvailable -Name $module
            if (-not $installedModule) {
                Write-Host "Module '$module' is not installed. Attempting to install..."
                try {
                    Install-Module -Name $module -Force -Scope AllUsers
                    Write-Host "Module '$module' installed successfully."
                }
                catch {
                    Write-Error "Failed to install module '$module'. Error: $_"
                }
            } else {
                Write-Host "Module '$module' is already installed. Checking for updates..."
                try {
                    Update-Module -Name $module -Force
                    Write-Host "Module '$module' updated successfully."
                }
                catch {
                    Write-Error "Failed to update module '$module'. Error: $_"
                }
            }
        }

        # Update all installed modules that are from PowerShell Gallery
        Write-Host "Updating all installed modules from the PowerShell Gallery..."
        $allModules = Get-Module -ListAvailable | Where-Object { $_.Path -like '*\PSGallery\*' }
        foreach ($mod in $allModules.Name) {
            try {
                Update-Module -Name $mod -Force
                Write-Host "Updated module '$mod' successfully."
            }
            catch {
                Write-Error "Failed to update module '$mod'. Error: $_"
            }
        }
    }

    End {
        Write-Verbose "Completed installing and updating modules."
    }
}

# Example usage
$modules = @('z', 'terminal-icons')
InstallAndUpdateModules -RequiredModules $modules -Verbose
